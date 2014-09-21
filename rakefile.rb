require 'rake/clean' # for auto-cleaning

desc 'run unit tests for mzid'
task :unit_tests do
  require_relative 'tests/test_all'
end

task :default => :unit_tests

