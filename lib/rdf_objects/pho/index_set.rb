module RDFObject    
  class Index
    attr_reader :name, :property, :analyzer, :weight
    def initialize(args={})
      unless args.empty?
        ["name","property","analyzer","weight"].each do |prop|
          if args[prop] || args[prop.to_s]
            self.send("set_prop".to_sym, (args[prop] || args[prop.to_s]))
          end
        end
      end
    end
    
    def set_name(name)
      @name = name
    end
    
    def set_property(property)
      if property.is_a?(RDFObject::Resource)
        @property = property
      else
        @property = RDFObject::Resource.new(property)
      end
    end
    
    def set_analyzer(analyzer)
      if analyzer.is_a?(RDFObject::Resource)
        @analyzer = analyzer
      else
        unless analyzer =~ /^http:\/\//
          analyzer = "http://schemas.talis.com/2007/bigfoot/analyzers#analyzer"
        end        
        @analyzer = RDFObject::Resource.new(analyzer)      
      end
    end
    
    def set_weight(boost)
      unless boost.nil?
        @weight = boost.to_f
      else
        @weight = nil
      end
    end
    
  end
    
  class IndexSet
    def initialize(store_name=nil)
      @fields = {}
      @store = nil
    end    
    
    def <<(index)
      @fields[index.name] = index
    end

    
    def get_index(name)
      return @fields[name]
    end
    
    def set_store(store_name)
      @store = store_name
    end
  
    
    def to_fpmap
      raise unless @store
      fpmap = RDFObject::Resource.new("#{@store}/config/fpmaps/1")
      fpmap.relate("[rdf:type]","http://schemas.talis.com/2006/bigfoot/configuration#FieldPredicateMap")
      @fields.values.each do |index|
        field = RDFObject::Resource.new("#{fpmap.uri}##{index.name}")
        field.relate("http://schemas.talis.com/2006/frame/schema#property", index.property)
        field.assert("http://schemas.talis.com/2006/frame/schema#name", index.name)
        if index.analyzer
          field.relate("http://schemas.talis.com/2006/bigfoot/configuration#analyzer", index.analyzer)
        end
        fpmap.relate("http://schemas.talis.com/2006/frame/schema#mappedDatatypeProperty", field)
      end
      fpmap
    end
    
    def to_qp
      raise unless @store
      qp = RDFObject::Resource.new("#{@store}/config/queryprofiles/1")
      qp.relate("[rdf:type]", "http://schemas.talis.com/2006/bigfoot/configuration#QueryProfile")
      @fields.values.each do |index|
        next unless index.weight
        weight = RDFObject::Resource.new("#{qp.uri}##{index.name}")
        weight.assert("http://schemas.talis.com/2006/bigfoot/configuration#weight", index.weight.to_s)
        weight.assert("http://schemas.talis.com/2006/frame/schema#name", index.name)
      end
      qp
    end
    
    def self.new_from_response(fpmap, qp)
      index_set = self.new(fpmap.uri.sub("/config/fpmaps/1",""))
      [*fpmap["http://schemas.talis.com/2006/frame/schema#mappedDatatypeProperty"]].each do |field|
        next unless field
        index = RDFObject::Index.new
        index.set_name(field["http://schemas.talis.com/2006/frame/schema#name"].to_s)
        index.set_property(field["http://schemas.talis.com/2006/frame/schema#property"].resource)
        if field["http://schemas.talis.com/2006/bigfoot/configuration#analyzer"]
          index.set_analyzer(field["http://schemas.talis.com/2006/bigfoot/configuration#analyzer"].resource)
        end
      end
      
      [*qp["http://schemas.talis.com/2006/bigfoot/configuration#fieldWeight"]].each do |weight|
        next unless weight
        name = weight["http://schemas.talis.com/2006/frame/schema#name"].to_s
        index = index_set.get_index(name)
        index.set_weight(weight["http://schemas.talis.com/2006/bigfoot/configuration#weight"])
      end
      return index_set
    end
  end
end