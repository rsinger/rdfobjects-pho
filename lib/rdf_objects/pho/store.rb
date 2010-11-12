module RDFObject
  module StoreResponse
    attr_accessor :collection, :resource
    def parse_response
      @collection = ::RDFObject::Parser.parse(body.content) unless body.content.empty? or status_code >= 300
    end
    
    def self.extended(o)
      o.parse_response
    end
  end
    
  class Store < Pho::Store
      
    def augment(data)
      d = case data.class.name
      when "String" then data
      when "RDFObject::Resource" then data.to_rss
      when "RDFObject::Collection" then data.to_rss
      else raise ArgumentError, "Argument 'data' must be an RSS 1.0 formatted string, RDFObject::Resource or RDFObject::Collection"
      end
      response = super(d)
      response.extend ::RDFObject::StoreResponse
      search_resource = response.collection.find_by_predicate_and_object("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://purl.org/rss/1.0/channel")
      search_resource.keys.each do |uri|
        if uri =~ /http:\/\/api\.talis\.com\/stores/
          response.resource = search_resource[uri]
        end
      end      
      return response
    end 
    
    def describe(uri, format="text/plain", etags=nil, if_match=false)
      response = super(uri, format, etags, if_match)
      response.extend ::RDFObject::StoreResponse
      response.resource = response.collection[uri]      
      return response
    end     
    
    def get_field_predicate_map(output=::Pho::ACCEPT_JSON)
      u = build_uri("/config/fpmaps/1")
      response = super(output)
      response.extend ::RDFObject::StoreResponse
      response.resource = response.collection[u]
      return response                  
    end

    def get_indexes
      fp_map_resp = get_field_predicate_map
      qp_resp = get_query_profile
      RDFObject::IndexSet.new_from_response(fp_map_resp.resource, qp_resp.resource)
    end
    
    def set_indexes(index_set)
      index_set.set_store(@storeuri)
      put_field_predicate_map(index_set.to_fpmap)
      put_query_profile(index_set.to_qp)
      get_indexes
    end
    
    def get_job(uri)
      response = super(uri)
      response.extend ::RDFObject::StoreResponse
      response.resource = response.collection[uri]
    end
    
    def get_jobs
      response = super
      response.extend ::RDFObject::StoreResponse
      response
    end
    
    def get_query_profile(output=::Pho::ACCEPT_JSON)
      u = build_uri("/config/queryprofiles/1")
      response = super(output)
      response.extend ::RDFObject::StoreResponse
      response.resource = response.collection[u]
      response
    end

    def put_field_predicate_map(fpmap)
      if fpmap.is_a?(RDFObject::Resource)
        rdf = fpmap.to_xml(4)
      elsif fpmap.is_a?(String)
        rdf = fpmap
      end
      u = build_uri("/config/fpmaps/1")
      headers = {"Content-Type" => "application/rdf+xml"}
      return @client.put(u, rdf, headers)      
    end
    
    def put_query_profile(qp)
      if qp.is_a?(RDFObject::Resource)
        rdf = qp.to_xml(4)
      elsif qp.is_a?(String)
        rdf = qp
      end      
      u = build_uri("/config/queryprofiles/1")
      headers = {"Content-Type" => "application/rdf+xml"}
      return @client.put(u, rdf, headers)      
    end
    
    def search(query, params=nil)
      response = super(query, params)
      response.extend ::RDFObject::StoreResponse
      search_resource = response.collection.find_by_predicate_and_object("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://purl.org/rss/1.0/channel")
      search_resource.keys.each do |uri|
        if uri =~ /http:\/\/api\.talis\.com\/stores/
          response.resource = search_resource[uri]
        end
      end
      return response      
    end

    def sparql_construct(query, format="application/rdf+xml", multisparql=false)
      response = super(query, format, multisparql)
      response.extend ::RDFObject::StoreResponse
      response
    end
        
    def sparql_describe(query, format="application/rdf+xml", multisparql=false)
      response = super(query, format, multisparql)
      response.extend ::RDFObject::StoreResponse
      response
    end
    
    def store_object(rdf_object, depth=0, graph_name=nil)
      unless rdf_object.is_a?(RDFObject::Node) || rdf_object.is_a?(RDFObject::Collection)
        raise ArgumentError, "Argument must be a RDFObject::Node or RDFObject::Collection"
      end
      store_data(rdf_object.to_xml(depth), graph_name)
    end
    
    def submit_changeset(rdf, versioned=false, graph_name=nil)
      unless rdf.is_a?(String) or rdf.is_a?(RDFObject::ChangeSet)
        raise ArgumentError, "Argument 'rdf' must be a String or RDFObject::ChangeSet"
      end
      data = case rdf.class.name
      when "String" then rdf
      else rdf.to_xml
      end
      super(data, versioned, graph_name)
    end
  end
end