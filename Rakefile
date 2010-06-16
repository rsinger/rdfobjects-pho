require "rake"

require "spec/rake/spectask"



desc "Run all specs"

Spec::Rake::SpecTask.new("specs") do |t|

  t.spec_files = FileList["specs/*.rb"]

end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rdfobjects-pho"
    gemspec.summary = "RDFObjects/Pho integration."
    gemspec.description = "A bridge to more easily use RDFObjects with Pho."
    gemspec.email = "rossfsinger@gmail.com"
    gemspec.homepage = "http://github.com/rsinger/rdfobjects-pho"
    gemspec.authors = ["Ross Singer"]
    gemspec.add_dependency('rdfobjects')
    gemspec.add_dependency('rdfobjects-changeset')  
    gemspec.files = Dir.glob("{lib,spec}/**/*") + ["README", "LICENSE"]
    gemspec.require_path = 'lib'    
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

