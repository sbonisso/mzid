$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'mzid/version'

Gem::Specification.new do |s|
   s.name = 'mzid'
   s.version = MzID::VERSION
   s.summary = "mzIdentML parser"
   s.description = "A simple gem to parse mzIdentML (mzid) files"

   s.authors = ["Stefano R.B."]
   s.email = 'sbonisso@ucsd.edu'
   
   all_files = `git ls-files`.split("\n")
   s.files = all_files.grep(/^(lib|bin|tests)/)
   s.executables = ["convert_mzid_to_csv"]
   s.test_files = `git ls-files -- tests/*`.split("\n")
   s.require_paths = ['lib']
   
   s.homepage = 'https://github.com/sbonisso/mzid'
   s.license = 'MIT'
   
   s.add_runtime_dependency 'ox', '~> 2.0'
   s.add_runtime_dependency 'nokogiri', '~> 1.6'
   s.add_runtime_dependency 'progressbar', ' ~> 0.21'
   
   s.add_development_dependency 'minitest', '~> 5.4'
   s.add_development_dependency 'minitest-reporters', '~> 1.0'
end
