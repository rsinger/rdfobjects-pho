module RDFObject
  module StoreResponse
    attr_accessor :collection, :resource
    def parse_response
      @collection = ::RDFObject::Parser.parse(body.content)
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
      response.parse_response
      return response
    end 
    
    def describe(uri, format="text/plain", etags=nil, if_match=false)
      response = super(uri, format, etags, if_match)
      response.extend ::RDFObject::StoreResponse
      response.parse_response
      response.resource = response.collection[uri]      
      return response
    end     
    
    def get_field_predicate_map(output=ACCEPT_JSON)
      u = build_uri("/config/fpmaps/1")
      response = super(output)
      response.extend ::RDFObject::StoreResponse
      response.parse_response
      response.resource = response.collection[u]
      return response                  
    end
    
    
    def search(query, params=nil)
      response = super(query, params)
      response.extend ::RDFObject::StoreResponse
      response.parse_response
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
      response.parse_response
      response
    end
        
    def sparql_describe(query, format="application/rdf+xml", multisparql=false)
      response = super(query, format, multisparql)
      response.extend ::RDFObject::StoreResponse
      response.parse_response
      response
    end
    
    def store_object(rdf_object, depth=0, graph_name=nil)
      unless rdf_object.is_a?(RDFObject::Resource) || rdf_object.is_a?(RDFObject::Collection)
        raise ArgumentError, "Argument must be a RDFObject::Resource or RDFObject::Collection"
      end
      store_data(rdf_object.to_xml(depth), graph_name)
    end
    
    def submit_changeset(rdf, versioned=false, graph_name=nil)
      unless rdf.is_a?(String) or rdf.is_a?(RDFObject::ChangeSet) or rdf.is_a?(RDFObject::VersionedChangeSet)
        raise ArgumentError, "Argument 'rdf' must be a String or RDFObject::ChangeSet"
      end
      data = case rdf.class.name
      when "String" then rdf
      else rdf.to_xml
      end
      versioned = true if rdf.is_a?(RDFObject::VersionedChangeSet)
      super(data, versioned, graph_name)
    end
  end
end