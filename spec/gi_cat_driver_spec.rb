require 'spec_helper'
require 'gi_cat_driver'
require 'webmock/rspec'

describe GiCatDriver do
  before(:all) do
    @base_url = "http://www.somecompany.com/"
    @gi_cat = GiCatDriver::GiCat.new(@base_url, "admin", "pass")
  end

  describe "requests" do
    it "can check that GI-Cat is running" do
      stub_request(:get, @base_url)
        .with(:headers => {
          'Accept'=>'*/*', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Faraday v0.8.7'
        }).to_return(:status => 200, :body => "", :headers => {})

      running = @gi_cat.is_running?

      expect(running).to be_true
      a_request(:get, @base_url).should have_been_made.once
    end
  end

  describe "profile configurations"
    it "retrieves the active profile id" do
      request_url = @base_url + "services/conf/giconf/configuration"
      stub_request(:get, request_url)
        .with(:headers => {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/xml',
          'User-Agent'=>'Ruby'
        }).to_return(:status => 200, :body => "1", :headers => {})

      profile_id = @gi_cat.get_active_profile_id

      a_request(:get, request_url).should have_been_made.once
      expect(profile_id).to eq "1"
    end

    it "can retrieve a profile id given a profile name" do
      request_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations"
      stub_request(:get,request_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :query => {:nameRepository => "gicat"})
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      # Find id for 'some_profile'
      profile_id = @gi_cat.find_profile_id("some_profile")

      a_request(:get, request_url).with(:query => {:nameRepository => "gicat"}).should have_been_made.once
      expect(profile_id).to eq("1")
    end

    it "throws an error if the profile cannot be found" do
      request_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations"
      stub_request(:get,request_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :query => {:nameRepository => "gicat"})
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      # Lambda hack to catch error http://stackoverflow.com/questions/2359439/expecting-errors-in-rspec-tests
      lambda {@gi_cat.find_profile_id "bad_name"}.should raise_error(RuntimeError)
    end

    it "can enable a profile given the name" do
      enable_conf_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1"
      stub_request(:get,enable_conf_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :query => {:opts => "active"})
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      active_conf_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations"
      stub_request(:get,active_conf_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :query => {:nameRepository => "gicat"})
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      conf_request_url = "http://www.somecompany.com/services/conf/giconf/configuration"
      stub_request(:get,conf_request_url)
        .with(:headers => {
          'Accept'=>'*/*', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'application/xml'
        }).to_return(:status => 200, :body => "1", :headers => {})

      @gi_cat.enable_profile "some_profile"

      a_request(:get, active_conf_url).with(:query => {:nameRepository => "gicat"}).should have_been_made.once
      expect(@gi_cat.get_active_profile_id).to eq "1"
    end
  end

  describe "Lucene indexing"
    it "enables Lucene for the active profile" do
      enable_lucene_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1/luceneEnabled"
      stub_request(:put,enable_lucene_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :body => "true").to_return(:status => 200, :body => "", :headers => {})

      conf_request_url = "http://www.somecompany.com/services/conf/giconf/configuration"
      stub_request(:get,conf_request_url)
        .with(:headers => {
          'Accept'=>'*/*', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'application/xml'
        }).to_return(:status => 200, :body => "1", :headers => {})

      enable_conf_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1"
      stub_request(:get,enable_conf_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Faraday v0.8.7', 
          'Content-Type'=>'*/*'
        }, :query => {:opts => "active"})
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      query_url = "http://www.somecompany.com/services/opensearchesip?bbox=&ct=&gdc=&lac=&loc=&luc=&outputFormat=&rel=&si=&st=arctic%20alaskan%20shrubs&te=&ts="
      stub_request(:get, query_url)
        .with(:headers => {
          'Accept'=>'*/*',
          'User-Agent'=>'Ruby'
        }).to_return(:status => 200, :body => File.new("spec/fixtures/opensearchesip_lucene_enabled.xml"), :headers => {})

      @gi_cat.enable_lucene

      @gi_cat.is_lucene_enabled?.should be_true
    end

    it "disables Lucene for the active profile" do
      disable_lucene_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1/luceneEnabled"
      stub_request(:put,disable_lucene_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :body => "false").to_return(:status => 200, :body => "", :headers => {})

      conf_request_url = "http://www.somecompany.com/services/conf/giconf/configuration"
      stub_request(:get,conf_request_url)
        .with(:headers => {
          'Accept'=>'*/*', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'application/xml'
        }).to_return(:status => 200, :body => "1", :headers => {})

      enable_conf_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1"
      stub_request(:get,enable_conf_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Faraday v0.8.7', 
          'Content-Type'=>'*/*'
        }, :query => {:opts => "active"})
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      query_url = "http://www.somecompany.com/services/opensearchesip?bbox=&ct=&gdc=&lac=&loc=&luc=&outputFormat=&rel=&si=&st=arctic%20alaskan%20shrubs&te=&ts="
      stub_request(:get, query_url)
        .with(:headers => {
          'Accept'=>'*/*',
          'User-Agent'=>'Ruby'
        }).to_return(:status => 200, :body => File.new("spec/fixtures/opensearchesip_lucene_disabled.xml"), :headers => {})

      @gi_cat.disable_lucene

      @gi_cat.is_lucene_enabled?.should be_false
    end

  end
end
