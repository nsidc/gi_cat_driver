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
      self.class.const_set("AUTHORIZATION_HEADERS", { :content_type => "*/*", :Accept => "application/xml", :Authorization => self.basic_auth_string })
    end

    # Basic Authorization used in the request headers
    def basic_auth_string
      "Basic " + Base64.encode64("#{@admin_username}:#{@admin_password}").rstrip
    end

    # Check whether GI-Cat is accessible
    def is_running?
      Faraday.get(@base_url + "/").status == 200
    end

    # Add a new profile with the given name
    def create_profile( profile_name )
      response = Faraday.post do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/newBroker"
        req.body = "inputNewName=#{profile_name}&nameBrokerCopy=%20"
        req.headers = AUTHORIZATION_HEADERS.merge({'enctype' => 'multipart/form-data',:content_type => 'application/x-www-form-urlencoded'})
      end

      profile_id = response.body
      return profile_id
    end

    # Remove a profile with the given name
    def delete_profile( profile_name )
      profile_id = find_profile_id( profile_name )
      response = Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}", { :opts => 'delete', :random => generate_random_number }
        req.headers = AUTHORIZATION_HEADERS.merge({'enctype'=>'multipart/form-data'})
      end

      profile_id = response.body
      return profile_id
    end

    # Retrieve the ID for a profile given the name
    # Returns an integer ID reference to the profile
    def find_profile_id( profile_name )
      response = Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations", :nameRepository => 'gicat'
        req.headers = AUTHORIZATION_HEADERS
      end

      profile_id = parse_profile_element(profile_name, response.body)

      return profile_id
    end

    # Returns an integer ID reference to the active profile
    def get_active_profile_id
      response = Faraday.get do |req|
        req.url "#{@base_url}/services/conf/giconf/configuration"
        req.headers = STANDARD_HEADERS
      end

      profile_id = response.body
      return profile_id
    end

    # Enable a profile with the specified name
    def enable_profile( profile_name )
      Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{find_profile_id(profile_name)}?opts=active"
        req.headers = AUTHORIZATION_HEADERS
      end
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
      query_string = EsipOpensearchQueryBuilder::get_query_string({ :st => "arctic%20alaskan%20shrubs" })
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
        confirm_harvest_done(harvester_id, harvester_title, timeout)
      end
    end

    #### Private Methods

    private

    def set_lucene_enabled( enabled )
      enable_lucene_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}/luceneEnabled"
      Faraday.put do |req|
        req.url enable_lucene_request
        req.body = enabled.to_s
        req.headers = AUTHORIZATION_HEADERS
        req.options[:timeout] = 300
      end

      activate_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}"
      Faraday.get(activate_profile_request, { :opts => "active" },
        AUTHORIZATION_HEADERS)
    end

    # Retrive the distributor id given a profile id
    def get_active_profile_distributor_id(id)
      active_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{id}"
      response = Faraday.get do |req|
        req.url active_profile_request
        req.headers = AUTHORIZATION_HEADERS
      end
      id = Nokogiri.XML(response.body).css("component id").text
      return id
    end

    # Given a profile id, put all the associated resource id and title into harvest info array
    def get_harvest_resources(profile_id)
      id = get_active_profile_distributor_id(profile_id)
      harvest_resource_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/distributors/#{id}"
      response = Faraday.get do |req|
        req.url harvest_resource_request
        req.headers = AUTHORIZATION_HEADERS
      end
      doc = Nokogiri::XML(response.body)
      harvestersinfo_array = {}
      doc.css("component").each do |component|
        harvestersinfo_array[component.css("id").text.to_sym] = component.css("title").text
      end
      return harvestersinfo_array
    end

    # Harvest from specified resource
    def harvest_resource_for_active_configuration(harvesterid, harvestername = "n/a")
      response = Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{self.get_active_profile_id}/harvesters/#{harvesterid}/start"
        req.headers = AUTHORIZATION_HEADERS
      end

      if response.status == 200
        puts "#{Time.now}: Initiate harvesting GI-Cat resource #{harvestername}. Please wait a couple minutes for the process to complete."
      else
        raise "Failed to initiate harvesting GI-Cat resource #{harvestername}."
        response.return!(request, result, &block)
      end
    end

    # Run a loop to request GI-Cat for the status of a harvest
    def harvest_request_is_done(harvester_id, harvester_name="n/a")
      while(1) do
        sleep 1    # Wait for one second

        # appending unique number at the end of the request to bypass cache
        request = @base_url + "/services/conf/giconf/status?id=#{harvester_id}&rand=#{generate_random_number}"

        response = Faraday.get do |req|
          req.url request
          req.headers = AUTHORIZATION_HEADERS
        end

        status = parse_status_xml(response.body, harvester_name)
        if status.eql? :error
          fail "Error harvesting the resource #{harvester_name}"
        elsif status.eql? :completed
          puts "Succesfully harvested #{harvester_name}"
          break
        end
      end
    end

    # Run till harvest all the resources are completed or time out
    def confirm_harvest_done(harvester_id, harvester_title, waitmax)
      begin
        puts "Info: Max wait time (timeout) for current profile is set to #{waitmax} seconds"
        Timeout::timeout(waitmax.to_i) do
          harvest_request_is_done(harvester_id.to_s, harvester_title)
        end
      rescue Timeout::Error
        puts "Warning: re-harvest is time out(#{waitmax} seconds, we are going to reuse the previous harvest results"
      end
    end

    def parse_profile_element( profile_name, xml_doc )
      configs = Nokogiri.XML(xml_doc)
      profile = configs.css("brokerConfiguration[name=#{profile_name}]")
      raise "The profile '" + profile_name + "' does not exist!" if profile.empty?

      return profile.attr('id').value
    end

    def parse_status_xml( xml_doc, harvester_name )
        xml = Nokogiri.XML(xml_doc)

        status = xml.css("status").text
        timestamp = Time.now

        puts "#{Time.now}: Harvest #{harvester_name} status: #{status}"

        case status
        when /Harvesting completed/
          return :completed
        when /Harvesting error/
          return :error
        else
          return :pending
        end

    end

    def generate_random_number
      return rand
    end
  end
end
