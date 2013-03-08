require "gi_cat_driver/version"
require "open-uri"
require "rest-client"
require "base64"
require 'nokogiri'

module GiCatDriver

  class GiCat
    ADMIN_USERNAME="admin"
    ADMIN_PASSWORD="abcd123$"

    def initialize( url )
      @base_url = url.sub(/\/+$/, '')  # strip trailing slashes
    end

    def base_url
      @base_url
    end

    def is_running?
      open(@base_url).status[0] == "200"
    end

    def basic_auth_string
      "Basic " + Base64.encode64("#{ADMIN_USERNAME}:#{ADMIN_PASSWORD}").rstrip
    end

    def standard_headers
      {
        :content_type => "application/xml",
        :Authorization => basic_auth_string
      }
    end

    def find_profile_id( profile_name )
      xmlDoc = RestClient.get(
        "#{@base_url}/services/conf/brokerConfigurations?nameRepository=gicat",
        standard_headers.merge({
          :content_type => "*/*",
          :Accept => 'application/xml'
        })
      )

      configs = Nokogiri.XML(xmlDoc)
      profile = configs.css("brokerConfiguration[name=#{profile_name}]")

      return (profile.empty? ? nil : profile.attr('id').value)
    end

    def enable_profile( profile_name )
      profile_id = find_profile_id(profile_name)
      activate_profile_url = "#{@base_url}/services/conf/brokerConfigurations/#{profile_id}?opts=active"
      RestClient.get(activate_profile_url, standard_headers)
    end

    def get_active_profile
      RestClient.get(
        "#{@base_url}/services/conf/giconf/configuration",
        standard_headers)
    end
  end
end
