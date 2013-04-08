require 'spec_helper'
require 'gi_cat_driver'
require 'webmock/rspec'

describe GiCatDriver do
  before(:each) do
    @base_url = "http://www.somecompany.com/"
  end

  describe "Standard requests" do
    it "can check that GI-Cat is running" do
      @gi_cat = GiCatDriver::GiCat.new(@base_url, "user", "pass")
      stub_request(:get, @base_url).with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.8.7'}).to_return(:status => 200, :body => "", :headers => {})
      expect(@gi_cat.is_running?).to be_true
      a_request(:get, @base_url).should have_been_made.once
    end
  end

  describe "Authorization" do
    subject { GiCatDriver::GiCat.new(@base_url, "user", "pass").basic_auth_string }

    auth_string = "Basic " + Base64.encode64("user:pass").rstrip
    it { should eq(auth_string) }
  end

  describe "Authorized requests" do
    before do
      @gi_cat = GiCatDriver::GiCat.new("http://www.testurl.com", "admin", "pass")
    end

    subject {
      @gi_cat.authorization_headers
    }

    it { should include(:Authorization => @gi_cat.basic_auth_string) }

    it "can access a protected service endpoint using the Authorization header" do
      request_url = "http://admin:pass@www.testurl.com/services/conf/brokerConfigurations"
      stub_request(:get, request_url).with(:headers => {'Accept'=>'application/xml', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.8.7'}, :query => {:nameRepository => "gicat"}).to_return(:status => 200, :body => File.new("fixtures/brokerConfigurations.xml"), :headers => {})
      profile_id = @gi_cat.find_profile_id("some_profile")
      a_request(:get, request_url).with(:query => {:nameRepository => "gicat"}).should have_been_made.once
      expect(profile_id).to eq("1")
    end
  end
end
