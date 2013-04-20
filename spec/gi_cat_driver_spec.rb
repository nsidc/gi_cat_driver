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

  describe "profile configurations" do
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
        .to_return(:status => 200, :body => "", :headers => {})

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

    it "adds a profile" do
      stub_request(:get, "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations").
        with(:headers => {'Accept'=>'application/xml', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'*/*', 'User-Agent'=>'Ruby'}, :query => {:nameRepository => "gicat"}).
        to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/newBroker").
        with(:headers => {'Accept'=>'application/xml', 'Content-Type'=>'application/x-www-form-urlencoded', 'Enctype'=>'multipart/form-data', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "5", :headers => {})

      profile_id = @gi_cat.create_profile "new-profile"

      profile_id.should eq "5"
    end

    it "deletes a profile" do
      stub_request(:get, "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations").
        with(:headers => {'Accept'=>'application/xml', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'*/*', 'User-Agent'=>'Ruby'}, :query => {:nameRepository => "gicat"}).
        to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      @gi_cat.stub(:generate_random_number).and_return("1")

      stub_request(:get, "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1?opts=delete&random=1").
        with(:headers => {'Accept'=>'application/xml', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "1", :headers => {})

      profile_id = @gi_cat.delete_profile "some_profile"

      profile_id.should eq "1"
    end
  end

  describe "Lucene indexing" do
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
        .to_return(:status => 200, :body => "", :headers => {})

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
        .to_return(:status => 200, :body => "", :headers => {})

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

  describe "resource harvesting into the database" do
    it "harvests all resources for the active profile" do
      conf_request_url = "http://www.somecompany.com/services/conf/giconf/configuration"
      stub_request(:get,conf_request_url)
        .with(:headers => {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby',
          'Content-Type'=>'application/xml'
        }).to_return(:status => 200, :body => "1", :headers => {})

      request_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1"
      stub_request(:get,request_url)
        .with(:headers => {
          'Accept'=>'application/xml',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby',
          'Content-Type'=>'*/*'
        })
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      get_resources_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1/distributors/UUID-6c89ab7d-82aa-446c-902e-0b1f6e412a45"
      stub_request(:get, get_resources_url)
        .with(:headers => {
          'Accept'=>'application/xml',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby',
          'Content-Type'=>'*/*'
        })
        .to_return(:status => 200, :body => File.new("spec/fixtures/distributors.xml"), :headers => {})

      start_harvest_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1/harvesters/UUID-a5d11731-9a58-4818-8018-c085cea8b6e3/start"
      stub_request(:get, start_harvest_url)
        .with(:headers => {
          'Accept'=>'application/xml',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'*/*',
          'User-Agent'=>'Ruby'
        })
        .to_return(:status => 200, :body => "", :headers => {})

      @gi_cat.stub(:generate_random_number) {0.1111}
      harvest_status_url = "http://admin:pass@www.somecompany.com/services/conf/giconf/status?id=UUID-a5d11731-9a58-4818-8018-c085cea8b6e3&rand=0.1111"
      stub_request(:get, harvest_status_url).
        with(:headers => {'Accept'=>'application/xml', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => '*/*', 'User-Agent' => 'Ruby'}).
        to_return(:status => 200, :body => File.new("spec/fixtures/status.xml"), :headers => [])

      @gi_cat.harvest_all_resources_for_active_configuration
    end
  end

  describe "accessor (xml feed resource) configurations" do
    it "creates a new feed resource for a profile" do
      profile_name = 'some_profile'
      accessor_configuration = {:nameComponent => 'fixture-nsidc-oai', :endPoint => 'http://scm.nsidc.org:3000/nsidc/oai.htm', :type => 'OAI-PMH/DIF', :versions => '2.0', :comment => '', :bindingAccessor => 'HTTP_GET', :nameContactPoint => '', :organizationContact => '', :mailContactPoint => '', :telephoneContactPoint => '', :startDate => '', :interval => 'P0Y0M0DT0H0M0S', :typeComponent => 'harvester', :stop => ''}

      stub_request(:get, "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations").
        with(:headers => {'Accept'=>'application/xml', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'*/*'}, :query => {:nameRepository => 'gicat'}).
        to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      enable_conf_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1"
      stub_request(:get,enable_conf_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        })
        .to_return(:status => 200, :body => File.new("spec/fixtures/brokerConfigurations.xml"), :headers => {})

      get_resources_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1/distributors/UUID-6c89ab7d-82aa-446c-902e-0b1f6e412a45"
      stub_request(:post, get_resources_url)
        .with(:headers => {
          'Accept'=>'application/xml',
          'User-Agent'=>'Ruby',
          'Content-Type'=>'application/x-www-form-urlencoded'
        }, :body => accessor_configuration)
        .to_return(:status => 200, :body => "UUID-dfe61211-56f4-4fb9-9f99-a7f4d95916c,UUID-0cd0c6a9-498c-400a-9bdd-20778ec62beb", :headers => {})

      update_resource_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations/1/accessors/UUID-dfe61211-56f4-4fb9-9f99-a7f4d95916c/update"
      stub_request(:post, update_resource_url)
        .with(:headers => {
          'Accept'=>'application/xml',
          'User-Agent'=>'Ruby',
          'Enctype'=>'multipart/form-data',
          'Content-Type'=>'application/x-www-form-urlencoded'
        }, :body => accessor_configuration)
        .to_return(:status => 200, :body => "Salvato", :headers => {})

      @gi_cat.create_accessor(profile_name, accessor_configuration)
    end
  end

end
