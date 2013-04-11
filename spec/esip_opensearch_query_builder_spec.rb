require 'spec_helper'
require 'gi_cat_driver/esip_opensearch_query_builder'

describe EsipOpensearchQueryBuilder do

  describe "get_query_string returns ESIP OpenSearch URLs" do
    it "Returns a URL with empty parameters when called without arguments" do
      query = EsipOpensearchQueryBuilder::get_query_string()
      query.should eq "?si=&ct=&st=&bbox=&rel=&loc=&ts=&te=&lac=&luc=&gdc=&outputFormat="
    end

    it "Returns a URL with a bounding box when called with a bbox argument" do
      query = EsipOpensearchQueryBuilder::get_query_string( :bbox => 'abcd')
      query.should eq "?si=&ct=&st=&bbox=abcd&rel=&loc=&ts=&te=&lac=&luc=&gdc=&outputFormat="
    end

    it "Returns a URL with a search term when called with a st argument" do
      query = EsipOpensearchQueryBuilder::get_query_string( :st => 'snow')
      query.should eq "?si=&ct=&st=snow&bbox=&rel=&loc=&ts=&te=&lac=&luc=&gdc=&outputFormat="
    end
  end
end
