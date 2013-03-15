require "gi_cat_driver/version"
require "gi_cat_driver/esip_opensearch_query_builder"
require "open-uri"
require "rest-client"
require "base64"
require 'nokogiri'
require 'timeout'

# The GI-Cat Driver
module GiCatDriver
  class GiCat

    ATOM_NAMESPACE = { "atom" => "http://www.w3.org/2005/Atom" }
    RELEVANCE_NAMESPACE = { "relevance" => "http://a9.com/-/opensearch/extensions/relevance/1.0/" }
    attr_accessor :base_url, :harvestersid_array
    
    def initialize( url, username, password )
      @base_url = url.sub(/\/+$/, '')
      @admin_username = username
      @admin_password = password
      @harvestersid_array = []
    end

    def basic_auth_string
      "Basic " + Base64.encode64("#{@admin_username}:#{@admin_password}").rstrip
    end

    def standard_headers
      {
        :content_type => "application/xml",
        :Authorization => basic_auth_string
      }
    end

    # Check whether the URL is accessible
    def is_running?
      open(@base_url).status[0] == "200"
    end

    # Retrieve the ID for a profile given the name
    # Returns an integer ID reference to the profile
    def find_profile_id( profile_name )
      get_profiles_request = "#{@base_url}/services/conf/brokerConfigurations?nameRepository=gicat"
      modified_headers = standard_headers.merge({
        :content_type => "*/*",
        :Accept => 'application/xml'
      })
      xml_doc = RestClient.get(get_profiles_request, modified_headers)
      profile = parse_profile_element(profile_name, xml_doc)

      return (profile.empty? ? nil : profile.attr('id').value)
    end

    def parse_profile_element( profile_name, xml_doc )
      configs = Nokogiri.XML(xml_doc)

      return configs.css("brokerConfiguration[name=#{profile_name}]")
    end

    # Enable a profile with the specified name
    def enable_profile( profile_name )
      profile_id = find_profile_id(profile_name)
      raise "The specified profile could not be found." if profile_id.nil?
      activate_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}?opts=active"

      RestClient.get(activate_profile_request, standard_headers)
    end

    # Retrieve the ID for the active profile
    # Returns an integer ID reference to the active profile
    def get_active_profile_id
      active_profile_request = "#{@base_url}/services/conf/giconf/configuration"

      return RestClient.get(active_profile_request, standard_headers)
    end

    # Enable Lucene indexes for GI-Cat search results
    def enable_lucene
      set_lucene_enabled true
    end
    
     # Disable Lucene indexes for GI-Cat search results
    def disable_lucene
      set_lucene_enabled false
    end

    def set_lucene_enabled( enabled )
      enable_lucene_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}/luceneEnabled"
      RestClient.put(enable_lucene_request,
        enabled.to_s,
        standard_headers)

      activate_profile_request = "#{@base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}?opts=active"
      RestClient.get(activate_profile_request,
        standard_headers)
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
    
    def add_new_uuids(new_harvesterids_array)
      @harvestersid_array += new_harvesterids_array
    end

    def harvest_resource_for_active_configuration(harvesterid)
      RestClient.get(
        "#{@base_url}/services/conf/brokerConfigurations/#{self.get_active_profile_id}/harvesters/#{harvesterid}/start",
        standard_headers){ |response, request, result, &block|
          case response.code
            when 200
              p "Harvest initiated.  Please wait a couple minutes for the process to complete."
            else
              raise "Failed to start GI-Cat resource harvest."
              response.return!(request, result, &block)
            end
        }
    end

    def harvest_all_resources_for_active_configuration
      harvestersid_array.each do |harvesterid|
        harvest_resource_for_active_configuration(harvesterid)
      end
    end

    def havest_request_is_done(harvesterid)
      while(1) do
        rnum=rand
        request = @base_url + "/services/conf/giconf/status?id=#{harvesterid}&rand=#{rnum}"
        response = RestClient.get request
        teststring = String.new(response.body)
        if teststring.include?("Harvesting completed")
          break
        end
      end
    end
    
    def confirm_harvest_done
      begin
        Timeout::timeout(10) do
          harvestersid_array.each  do |harvesterid|
            havest_request_is_done(harvesterid)
          end
        end
      rescue Timeout::Error
        puts "Warning: reharvest is time out, we are going to reuse the previous harvest results"
      end
    end
    
  end
end
