class RDFObject::Resource  
  def to_rss
    namespaces, rdf_data = self.rss_item_block
    unless namespaces["xmlns:rdf"]
      if  x = namespaces.index("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
        namespaces.delete(x)
      end
      namespaces["xmlns:rdf"] = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    end
    namespaces["xmlns"] = "http://purl.org/rss/1.0/"
    uri = self.uri.sub(/#.*$/,".rss")
    rdf = "<rdf:RDF"
    namespaces.each_pair {|key, value| rdf << " #{key}=\"#{value}\""}
    rdf <<">"
    rdf << "<channel rdf:about=\"#{uri}\"><title>#{self.uri}</title><link>#{self.uri}</link>"
    rdf << "<description>#{self.uri}</description><items><rdf:Seq><rdf:li resource=\"#{self.uri}\" /></rdf:Seq></items>"
    rdf << "</channel>"
    rdf << rdf_data
    rdf << "</rdf:RDF>"
    rdf      
  end   
  
  def rss_item_block
    rdf = "<item #{xml_subject_attribute}>"
    rdf << "<title>Item</title>"
    rdf << "<link>#{self.uri}</link>"
    namespaces = {}
    Curie.get_mappings.each_pair do |key, value|
      if self.respond_to?(key.to_sym)
        self.send(key.to_sym).each_pair do | predicate, objects |
          [*objects].each do | object |
            rdf << "<#{key}:#{predicate}"
            namespaces["xmlns:#{key}"] = "#{Curie.parse("[#{key}:]")}"
            if object.is_a?(RDFObject::ResourceReference) || object.is_a?(RDFObject::BlankNode)
              rdf << " #{object.xml_object_attribute} />"              
            else
              if object.language
                rdf << " xml:lang=\"#{object.language}\""
              end
              if object.datatype
                rdf << " rdf:datatype=\"#{object.datatype}\""
              end
              rdf << ">#{CGI.escapeHTML(object.to_s)}</#{key}:#{predicate}>"
            end
          end
        end
      end
    end
    rdf << "</item>"
    [namespaces, rdf]
  end   
  
  def empty_graph?
    Curie.get_mappings.each do | prefix, uri |
      if self.respond_to?(prefix.to_sym)
        if uri == "http://schemas.talis.com/2005/dir/schema#"
          self["http://schemas.talis.com/2005/dir/schema#"].each_pair do |property, value|
            next if property == 'etag'
            return false
          end
        else
          return false
        end
      end
    end
    return true    
  end
end

class RDFObject::Collection
  def to_rss
    uuid = ::UUID.generate
    uri = "info:uuid/#{uuid}"
    namespaces = {}
    rdf_data = ""    
    self.values.each do |item|
      ns, rss_data = item.rss_item_block
      namespaces.merge!(ns)
      rdf_data << rss_data      
    end

    unless namespaces["xmlns:rdf"]
      if  x = namespaces.index("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
        namespaces.delete(x)
      end
      namespaces["xmlns:rdf"] = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    end
    namespaces["xmlns"] = "http://purl.org/rss/1.0/"
    rdf = "<rdf:RDF"
    namespaces.each_pair {|key, value| rdf << " #{key}=\"#{value}\""}
    rdf <<">"
    rdf << "<channel rdf:about=\"#{uri}\"><title>RDFObject Collection</title><link>#{uri}</link>"
    rdf << "<description>RDFOject Collection</description><items><rdf:Seq>"
    self.keys.each do |uri|
      rdf << "<rdf:li resource=\"#{uri}\" />"
    end
    rdf << "</rdf:Seq></items>"
    rdf << "</channel>"
    
      
    rdf << rdf_data
    rdf << "</rdf:RDF>"
    rdf      
  end  
end