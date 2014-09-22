$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'mzid/version'

Gem::Specification.new do |s|
s.name = 'mzid'
s.version = MzID::VERSION
s.summary = "mzIdentML parser"
s.description = "A simple gem to parse mzIdentML files"
s.authors = ["Stefano R.B."]
s.email = 'sbonisso@ucsd.edu'
s.files = Dir['lib/**/*.rb'] + Dir['tests/*'] 
s.require_paths = ['lib']
s.homepage = 'https://github.com/sbonisso/mzid'
s.license = 'MIT'
s.add_dependency 'nokogiri'
s.add_dependency 'progressbar'
end