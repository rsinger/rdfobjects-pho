require 'rubygems'
require 'pho'
require 'rdf_objects'
require 'rdf_objects/changeset'
require 'cgi'
require 'uuid'

module RDFObject
  require File.dirname(__FILE__) + '/pho/store' 
  require File.dirname(__FILE__) + '/pho/rdf_resource'   
  require File.dirname(__FILE__) + '/pho/index_set'     
end