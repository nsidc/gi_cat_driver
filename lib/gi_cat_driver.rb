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
    OPENSEARCH_NAMESPACE = { "opensearch" => "http://a9.com/-/spec/opensearch/1.1/" }
    RELEVANCE_NAMESPACE = { "relevance" => "http://a9.com/-/opensearch/extensions/relevance/1.0/" }

    attr_accessor :base_url

    def initialize( url, username, password )
      @base_url = url.sub(/\/+$/, '')
      @admin_username = username
      @admin_password = password

      @standard_headers = { :content_type => "application/xml" }
      @authorization_headers = { :content_type => "*/*", :Accept => "application/xml", :Authorization => self.basic_auth_string }
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
        req.headers = @authorization_headers.merge({'enctype' => 'multipart/form-data',:content_type => 'application/x-www-form-urlencoded'})
      end

      profile_id = response.body
      return profile_id
    end

    # Remove a profile with the given name
    def delete_profile( profile_name )
      profile_id = find_profile_id( profile_name )
      response = Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}", { :opts => 'delete', :random => generate_random_number }
        req.headers = @authorization_headers.merge({'enctype'=>'multipart/form-data'})
      end

      profile_id = response.body
      return profile_id
    end

    # Retrieve the ID for a profile given the name
    # Returns an integer ID reference to the profile
    def find_profile_id( profile_name )
      response = Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations", :nameRepository => 'gicat'
        req.headers = @authorization_headers
      end

      profile_id = parse_profile_element(profile_name, response.body)

      return profile_id
    end

    # Returns an integer ID reference to the active profile
    def get_active_profile_id
      response = Faraday.get do |req|
        req.url "#{@base_url}/services/conf/giconf/configuration"
        req.headers = @standard_headers
      end

      profile_id = response.body
      return profile_id
    end

    # Enable a profile with the specified name
    def enable_profile( profile_name )
      Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{find_profile_id(profile_name)}?opts=active"
        req.headers = @authorization_headers
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

    # Perform an ESIP OpenSearch query using a search term against GI-Cat and returns a Nokogiri XML document
    def query_esip_opensearch( search_term )
      query_string = EsipOpensearchQueryBuilder::get_query_string({ :st => search_term })

      begin
        file = open("#{@base_url}/services/opensearchesip#{query_string}")
      rescue => e
        raise "Failed to query GI-Cat ESIP OpenSearch interface."
      end

      return Nokogiri::XML(file)
    end

    # Find out whether Lucene indexing is turned on for the current profile
    # It is desirable to use REST to query GI-Cat for the value of this setting but GI-Cat does not yet support this.  
    # Instead, run a query and check that a 'relevance:score' element is present.
    # Returns true if Lucene is turned on
    def is_lucene_enabled?
      results = query_esip_opensearch("arctic%20alaskan%20shrubs")

      result_scores = results.xpath('//atom:feed/atom:entry/relevance:score', ATOM_NAMESPACE.merge(RELEVANCE_NAMESPACE))
      result_scores.map { |score| score.text }

      return result_scores.count > 0
    end

    # Parse the totalResults element in an OpenSearch ESIP XML document
    def get_total_results( xml_doc )
      return xml_doc.xpath('//atom:feed/opensearch:totalResults', ATOM_NAMESPACE.merge(OPENSEARCH_NAMESPACE)).text.to_i
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

    # Create an accessor (xml feed resource) for the given profile with the provided accessor configuration
    def create_accessor( profile_name, accessor_configuration )
      profile_id = find_profile_id( profile_name )
      distributor_id = get_active_profile_distributor_id(profile_id)

      response = Faraday.post do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/distributors/#{distributor_id}"
        req.headers = @authorization_headers.merge({:enctype=>'multipart/form-data', :content_type=>'application/x-www-form-urlencoded'})
        req.body = accessor_configuration
      end

      # The response contains a comma separated list of the accessor id as well as the harvester id
      (accessor_id, harvester_id) = response.body.split(',', 2)

      update_accessor_configuration( profile_id, accessor_id, accessor_configuration )

      enable_profile profile_name

      return accessor_id
    end

    # Remove an accessor (xml feed resource) with the given name from the given profile
    def delete_accessor( profile_name, accessor_name )
      profile_id = find_profile_id(profile_name)
      harvester_id = find_harvester_id(profile_name, accessor_name)

      Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/harvesters/#{harvester_id}", { :delete => 'true', :random => generate_random_number }
        req.headers = @authorization_headers.merge({:enctype=>'multipart/form-data'})
      end
    end

    # Publish an interface to access GI-Cat data for the given profile name
    # The interface_configuration is a hash that defines a 'profiler' and 'path'
    def publish_interface( profile_name, interface_configuration )
      profile_id = find_profile_id(profile_name)

      response = Faraday.post do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/profilers/"
        req.headers = @authorization_headers.merge({:enctype=>'multipart/form-data', :content_type=>'application/x-www-form-urlencoded'})
        req.body = interface_configuration
      end

      return response.body
    end

    def unpublish_interface( profile_name, interface_name )
      profile_id = find_profile_id(profile_name)

      Faraday.get do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/profilers/#{interface_name}", { :delete => 'true', :random => generate_random_number }
        req.headers = @authorization_headers.merge({:enctype=>'multipart/form-data', :content_type=>'application/x-www-form-urlencoded'})
      end
    end

    #### Private Methods

    private

    def set_lucene_enabled( enabled )
      enable_lucene_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}/luceneEnabled"
      Faraday.put do |req|
        req.url enable_lucene_request
        req.body = enabled.to_s
        req.headers = @authorization_headers
        req.options[:timeout] = 300
      end

      activate_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}"
      Faraday.get(activate_profile_request, { :opts => "active" },
        @authorization_headers)
    end

    # Retrieve the harvester id given a profile name and accessor name
    def find_harvester_id( profile_name, accessor_name )
      profile_id = find_profile_id(profile_name)

      distributor_id = get_active_profile_distributor_id(profile_id)

      harvester_id = get_active_profile_harvester_id(profile_id, distributor_id)

      return harvester_id
    end

    # Retrieve the distributor id given a profile id
    def get_active_profile_distributor_id(profile_id)
      active_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}"
      response = Faraday.get do |req|
        req.url active_profile_request
        req.headers = @authorization_headers
      end
      distributor_id = Nokogiri.XML(response.body).css("component id").text
      return distributor_id
    end

    # Retrieve the harvester id given a profile id and distributor id
    def get_active_profile_harvester_id(profile_id, distributor_id)
      harvester_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/distributors/#{distributor_id}"
      response = Faraday.get do |req|
        req.url harvester_request
        req.headers = @authorization_headers
      end
      harvester_id = Nokogiri.XML(response.body).css("component id").text
      return harvester_id
    end

    # Retrieve the accessor id given a profile id and harvester id
    def get_active_profile_accessor_id(profile_id, harvester_id)
      accessor_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/harvesters/#{harvester_id}"
      response = Faraday.get do |req|
        req.url accessor_request
        req.headers = @authorization_headers
      end
      accessor_id = Nokogiri.XML(response.body).css("component id").text
      return accessor_id
    end

    def get_active_profile_accessor_name(profile_id, accessor_id)
      accessor_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/accessors/#{accessor_id}"
      response = Faraday.get do |req|
        req.url accessor_request
        req.headers = @authorization_headers
      end
      accessor = Nokogiri.XML(response.body).css("accessor name").text
      return accessor
    end

    # Given a profile id, put all the associated resource id and title into harvest info array
    def get_harvest_resources(profile_id)
      id = get_active_profile_distributor_id(profile_id)
      harvest_resource_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/distributors/#{id}"
      response = Faraday.get do |req|
        req.url harvest_resource_request
        req.headers = @authorization_headers
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
        req.headers = @authorization_headers
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
          req.headers = @authorization_headers
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

    def update_accessor_configuration( profile_id, accessor_id, accessor_configuration )
      response = Faraday.post do |req|
        req.url "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}/accessors/#{accessor_id}/update"
        req.headers = @authorization_headers.merge({:enctype=>'multipart/form-data', :content_type=>'application/x-www-form-urlencoded'})
        req.body = accessor_configuration
      end
      return response.body
    end

    def generate_random_number
      return rand
    end
  end
end
