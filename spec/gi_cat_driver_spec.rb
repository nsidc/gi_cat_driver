require 'spec_helper'
require 'gi_cat_driver'

describe GiCatDriver do
  before(:each) do
    @base_url = ENV["URL"] or throw "Error: Must provide URL environment variable for GI-Cat!"
    @gi_cat = GiCatDriver::GiCat.new(@base_url)
  end

  it "Initializes with a base url that points to an instance of GI-Cat" do
    expected = @base_url.sub(/\/+$/, '')
    @gi_cat.base_url.should eq(expected)
  end

  it "Is able to send requests to GI-Cat" do
    @gi_cat.is_running?.should be_true
  end

  it "Sends requests with basic header information" do
    @gi_cat.standard_headers[:content_type].should eq "application/xml"
  end

  it "Can authorize access using the Authorization header" do
    @gi_cat.standard_headers[:Authorization].should eq "Basic YWRtaW46YWJjZDEyMyQ="
  end

  it "Retrieves a profile id given the name" do
    @gi_cat.find_profile_id("NORWEGIAN_CISL_NSIDC_EOL").should eq "1"
  end

  it "Enables a profile given the name" do
    @gi_cat.enable_profile("NORWEGIAN_CISL_NSIDC_EOL")
    @gi_cat.get_active_profile.should eq "1"
  end
end
