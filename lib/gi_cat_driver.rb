# The GI-Cat Driver controls GI-Cat configurations and actions using HTTP requests.
#
require "gi_cat_driver/version"
require "gi_cat_driver/esip_opensearch_query_builder"
require "open-uri"
require "faraday"
require "base64"
require 'nokogiri'
require 'timeout'

#### Public Interface

# 'GiCatDriver::GiCat.new' creates a new GiCat object that provides an interface to many configuration options and controls available in GI-Cat.
#
module GiCatDriver
  class GiCat

    ATOM_NAMESPACE = { "atom" => "http://www.w3.org/2005/Atom" }
    RELEVANCE_NAMESPACE = { "relevance" => "http://a9.com/-/opensearch/extensions/relevance/1.0/" }
    attr_accessor :base_url

    def initialize( url, username, password )
      @base_url = url.sub(/\/+$/, '')
      @admin_username = username
      @admin_password = password

      # Set up a constant containing the standard request headers
      self.class.const_set("STANDARD_HEADERS", { :content_type => "application/xml" })
      self.class.const_set("AUTHORIZATION_HEADERS", { :content_type => "*/*", :Accept => "application/xml" :Authorization => self.basic_auth_string })
    end

    # Basic Authorization used in the request headers
    def basic_auth_string
      "Basic " + Base64.encode64("#{@admin_username}:#{@admin_password}").rstrip
    end

    # Check whether GI-Cat is accessible
    def is_running?
      Faraday.get(@base_url + "/").status == 200
    end

    # Retrieve the ID for a profile given the name
    # Returns an integer ID reference to the profile
    def find_profile_id( profile_name )
      response = Faraday.get do |req|
        req.url @base_url + '/services/conf/brokerConfigurations', :nameRepository => 'gicat'
        req.headers = AUTHORIZATION_HEADERS
      end

      profile_id = parse_profile_element(profile_name, response.body)
      raise "The profile '" + profile_name + "' does not exist!" if profile_id.empty?

      return profile_id.attr('id').value
    end

    # Enable a profile with the specified name
    def enable_profile( profile_name )
      profile_id = find_profile_id(profile_name)

      activate_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}?opts=active"

      Faraday.get(activate_profile_request, STANDARD_HEADERS)
    end

    # Returns an integer ID reference to the active profile
    def get_active_profile_id
      active_profile_request = "#{@base_url}/services/conf/giconf/configuration"

      return Faraday.get(active_profile_request, STANDARD_HEADERS)
    end

    # Enable Lucene indexes for GI-Cat search results
    def enable_lucene
      set_lucene_enabled true
    end

    # Disable Lucene indexes for GI-Cat search results
    def disable_lucene
      set_lucene_enabled false
    end

    # Find out whether Lucene indexing is turned on for the current profile
    # It is desirable to use REST to query GI-Cat for the value of this setting but GI-Cat does not yet support this.  
    # Instead, run a query and check that a 'relevance:score' element is present.
    # Returns true if Lucene is turned on
    def is_lucene_enabled?
      query_string = EsipOpensearchQueryBuilder::get_query_string({ :st => "snow" })
      results = Nokogiri::XML(open("#{@base_url}/services/opensearchesip#{query_string}"))

      result_scores = results.xpath('//atom:feed/atom:entry/relevance:score', ATOM_NAMESPACE.merge(RELEVANCE_NAMESPACE))
      result_scores.map { |score| score.text }

      return result_scores.count > 0
    end

    # Harvest all resource in the active profile
    # The default timeout is 1500 seconds (25 minutes)
    def harvest_all_resources_for_active_configuration timeout=1500
      harvestersinfo_array = get_harvest_resources(get_active_profile_id)
      harvestersinfo_array.each do |harvester_id, harvester_title|
        harvest_resource_for_active_configuration(harvester_id.to_s, harvester_title)
      end
      confirm_harvest_done(harvestersinfo_array, timeout)
    end

    #### Private Methods

    private

    def set_lucene_enabled( enabled )
      enable_lucene_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}/luceneEnabled"
      Faraday.put(enable_lucene_request,
        enabled.to_s,
        STANDARD_HEADERS)

      activate_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}?opts=active"
      Faraday.get(activate_profile_request,
        STANDARD_HEADERS)
    end

    # Retrieve the profile element using the name
    def parse_profile_element( profile_name, xml_doc )
      configs = Nokogiri.XML(xml_doc)

      return configs.css("brokerConfiguration[name=#{profile_name}]")
    end

    # Retrive the distributor id given a profile id
    def get_active_profile_distributor_id(id)
      active_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{id}"
      response = RestClient.get(active_profile_request, STANDARD_HEADERS)
      id = Nokogiri::XML(response).css("component id").text
      return id
    end

    # Given a profile id, put all the associated resource id and title into harvest info array
    def get_harvest_resources(profile_id)
      id = get_active_profile_distributor_id(profile_id)
      harvest_resource_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/distributors/#{id}"
      response = RestClient.get(harvest_resource_request, STANDARD_HEADERS)
      doc = Nokogiri::XML(response)
      harvestersinfo_array = {}
      doc.css("component").each do |component|
        harvestersinfo_array[component.css("id").text.to_sym] = component.css("title").text
      end
      return harvestersinfo_array
    end

    # Harvest from specified resource
    def harvest_resource_for_active_configuration(harvesterid, harvestername = "n/a")
      Faraday.get(
        "#{@base_url}/services/conf/brokerConfigurations/#{self.get_active_profile_id}/harvesters/#{harvesterid}/start",
        STANDARD_HEADERS) do |response, request, result, &block|
          case response.code
          when 200
            puts "#{Time.now}: Initiate harvesting GI-Cat resource #{harvestername}. Please wait a couple minutes for the process to complete."
          else
            raise "Failed to initiate harvesting GI-Cat resource #{harvestername}."
            response.return!(request, result, &block)
          end
        end
    end

    # Parsing and handle the harvest status
    def harvest_status(status, harvestername="default")
      timestamp = Time.now
      puts "#{Time.now}: Harvest #{harvestername} status: #{status}"
      case status
      when /Harvesting completed/
        return :completed
      when /Harvesting error/
        return :error
      else
        return :pending
      end
    end

    # Run till the harvest of a resource is completed
    def harvest_request_is_done(harvesterid, harvestername="n/a")
      while(1) do
        sleep 10    # Wait for ten seconds

        rnum=rand
        request = @base_url + "/services/conf/giconf/status?id=#{harvesterid}&rand=#{rnum}"

        response = Faraday.get request
        responsexml = Nokogiri::XML::Reader(response.body)
        responsexml.each do |node|
          if node.name == "status" && !node.inner_xml.empty?
            status = harvest_status(node.inner_xml, harvestername)
            if status.eql? :error
              fail "Error harvesting the resource #{harvestername}"
            elsif status.eql? :completed
              puts "Succesfully harvested #{harvestername}"
              return
            end
          end
        end
      end
    end

    # Run till harvest all the resources are completed or time out
    def confirm_harvest_done(harvestersinfo_array, waitmax)
      begin
        puts "Info: Max wait time (timeout) for current profile is set to #{waitmax} seconds"
        Timeout::timeout(waitmax.to_i) do
          harvestersinfo_array.each do |harvester_id, harvester_title|
            harvest_request_is_done(harvester_id.to_s, harvester_title)
          end
        end
      rescue Timeout::Error
        puts "Warning: re-harvest is time out(#{waitmax} seconds, we are going to reuse the previous harvest results"
      end
    end

  end
end
