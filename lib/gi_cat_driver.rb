require "gi_cat_driver/version"
require "gi_cat_driver/esip_opensearch_query_builder"
require "open-uri"
require "rest-client"
require "base64"
require 'nokogiri'

# The GI-Cat Driver
module GiCatDriver
  class GiCat

    ATOM_NAMESPACE = { "atom" => "http://www.w3.org/2005/Atom" }
    RELEVANCE_NAMESPACE = { "relevance" => "http://a9.com/-/opensearch/extensions/relevance/1.0/" }
    attr_accessor :base_url
    
    def initialize( url, username, password )
      self.base_url = url.sub(/\/+$/, '') 
      @admin_username = username
      @admin_password = password
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
      open(self.base_url).status[0] == "200"
    end

    # Retrieve the ID for a profile given the name
    # Returns an integer ID reference to the profile
    def find_profile_id( profile_name )
      get_profiles_request = "#{self.base_url}/services/conf/brokerConfigurations?nameRepository=gicat"
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
      activate_profile_request = "#{self.base_url}/services/conf/brokerConfigurations/#{profile_id}?opts=active"

      RestClient.get(activate_profile_request, standard_headers)
    end

    # Retrieve the ID for the active profile
    # Returns an integer ID reference to the active profile
    def get_active_profile_id
      active_profile_request = "#{self.base_url}/services/conf/giconf/configuration"

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
      enable_lucene_request = "#{self.base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}/luceneEnabled"
      RestClient.put(enable_lucene_request,
        enabled.to_s,
        standard_headers)

      activate_profile_request = "#{self.base_url}/services/conf/brokerConfigurations/#{get_active_profile_id}?opts=active"
      RestClient.get(activate_profile_request,
        standard_headers)
    end

    # Find out whether Lucene indexing is turned on for the current profile
    # It is desirable to use REST to query GI-Cat for the value of this setting but GI-Cat does not yet support this.  
    # Instead, run a query and check that a 'relevance:score' element is present.
    # Returns true if Lucene is turned on
    def is_lucene_enabled?
      query_string = EsipOpensearchQueryBuilder::get_query_string({ :st => "snow" })
      results = Nokogiri::XML(open("#{self.base_url}/services/opensearchesip#{query_string}"))

      result_scores = results.xpath('//atom:feed/atom:entry/relevance:score', ATOM_NAMESPACE.merge(RELEVANCE_NAMESPACE))
      result_scores.map { |score| score.text }

      return result_scores.count > 0
    end
  end
end
