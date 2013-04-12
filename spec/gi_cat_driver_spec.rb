require 'spec_helper'
require 'gi_cat_driver'

describe GiCatDriver do
  before(:each) do
    @base_url = "http://www.somecompany.com/"
    @gi_cat = GiCatDriver::GiCat.new(@base_url, "admin", "abcd123$")
  end

#  describe "Standard requests" do
    #it "Is able to send requests to GI-Cat" do
      #@gi_cat.is_running?.should be_true
    #end

#   it "Sends requests with basic header information" do
#      @gi_cat.standard_headers[:content_type].should eq "application/xml"
#    end
#
#    it "Can authorize access using the Authorization header" do
#      @gi_cat.standard_headers[:Authorization].should eq "Basic YWRtaW46YWJjZDEyMyQ="
#    end
#  end

  #describe "Profile management" do
    #it "Retrieves a profile id given the name" do
      #@gi_cat.find_profile_id("NORWEGIAN_CISL_NSIDC_EOL").should eq "1"
    #end

    #it "Throws an error if the profile cannot be found" do
      #@gi_cat.find_profile_id("notaprofile").should be_nil
    #end

    #it "Enables a profile given the name" do
      #@gi_cat.enable_profile("NORWEGIAN_CISL_NSIDC_EOL")
      #@gi_cat.get_active_profile_id.should eq "1"
    #end

    #it "Does not enable a profile if the profile cannot be found" do
      #expect { @gi_cat.enable_profile("notaprofile") }.to raise_error("The specified profile could not be found.")
    #end
  #end

  #describe "Lucene Indexing" do
    #it "Enables Lucene for the active profile" do
      #@gi_cat.enable_lucene
      #@gi_cat.is_lucene_enabled?.should be_true
    #end
  #end
end
