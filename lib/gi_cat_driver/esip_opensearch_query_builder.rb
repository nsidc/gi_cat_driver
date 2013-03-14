
# The EsipOpensearchQueryBuilder uses a hash of relevant key/value pairs to construct a string of parameters for the EsipOpensearchService
module EsipOpensearchQueryBuilder

  class QueryBuilder
    def assemble_query(params)
      return "?" + params.collect{ |k, v| "#{k}=#{v}" }.join("&")
    end
  end

  def self.get_query_string( query_params={} )
    all_params = { 
      :si => '', 
      :ct => '', 
      :st => '', 
      :bbox => '', 
      :rel => '', 
      :loc => '', 
      :ts => '', 
      :te => '', 
      :lac => '', 
      :luc => '', 
      :outputFormat => ''
    }.merge(query_params)

    builder = QueryBuilder.new()
    return builder.assemble_query(all_params)
  end
end
