require 'spec_helper'
require 'esip_opensearch_query_builder'

describe EsipOpensearchQueryBuilder do
  it "Returns an ESIP OpenSearch URL with empty parameters for the default query" do
    query = EsipOpensearchQueryBuilder::get_query_string()
    query.should eq "?si=&ct=&st=&bbox=&rel=&loc=&ts=&te=&lac=&luc=&outputFormat="
  end

  it "Returns an ESIP OpenSearch URL with a bounding box constraint given a bbox parameter" do
    query = EsipOpensearchQueryBuilder::get_query_string( :bbox => 'abcd')
    query.should eq "?si=&ct=&st=&bbox=abcd&rel=&loc=&ts=&te=&lac=&luc=&outputFormat="
  end

  it "Returns an ESIP OpenSearch URL with a search term given a st parameter" do
    query = EsipOpensearchQueryBuilder::get_query_string( :st => 'snow')
    query.should eq "?si=&ct=&st=snow&bbox=&rel=&loc=&ts=&te=&lac=&luc=&outputFormat="
  end
end
