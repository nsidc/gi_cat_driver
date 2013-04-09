require 'spec_helper'
require 'gi_cat_driver'
require 'webmock/rspec'

describe GiCatDriver do
  before(:each) do
    @base_url = "http://www.somecompany.com/"
  end

  describe "requests" do
    it "can check that GI-Cat is running" do
      @gi_cat = GiCatDriver::GiCat.new(@base_url, "user", "pass")
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

  describe "authorized requests" do
    it "can retrieve a profile id given a profile name" do
      gi_cat = GiCatDriver::GiCat.new(@base_url, "admin", "pass")
      request_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations"
      stub_request(:get,request_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :query => {:nameRepository => "gicat"})
        .to_return(:status => 200, :body => File.new("fixtures/brokerConfigurations.xml"), :headers => {})

      # Find id for 'some_profile'
      profile_id = gi_cat.find_profile_id("some_profile")

      a_request(:get, request_url).with(:query => {:nameRepository => "gicat"}).should have_been_made.once
      expect(profile_id).to eq("1")
    end

    it "to find a profile id throws an error if the profile cannot be found" do
      gi_cat = GiCatDriver::GiCat.new(@base_url, "admin", "pass")
      request_url = "http://admin:pass@www.somecompany.com/services/conf/brokerConfigurations"
      stub_request(:get,request_url)
        .with(:headers => {
          'Accept'=>'application/xml', 
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
          'User-Agent'=>'Ruby', 
          'Content-Type'=>'*/*'
        }, :query => {:nameRepository => "gicat"})
        .to_return(:status => 200, :body => File.new("fixtures/brokerConfigurations.xml"), :headers => {})

      # Lambda hack to catch error http://stackoverflow.com/questions/2359439/expecting-errors-in-rspec-tests
      lambda {gi_cat.find_profile_id "bad_name"}.should raise_error(RuntimeError)
    end
  end
end
