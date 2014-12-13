#!/usr/bin/env ruby

require_relative 'load_helper'
require 'mzid'
require 'csv'
require 'progressbar'
require 'optparse'


options = {}
optparse = OptionParser.new do |opt|
  opt.banner = "Usage: results.mzid [OPTIONS]"
  opt.separator  ""
  opt.separator  "Options"
  
  options[:verbose] = false
  opt.on("-v", "--verbose", "flag for verbose output or silent output") do |verbose|
    options[:verbose] = verbose
  end
  
  options[:mods] = false
  opt.on("-m", "--mods", "flag if the search contained modifications") do |ptm|
    options[:mods] = ptm
  end

  opt.on("-o","--output FILE","output file name, if unspecified will create a results.csv file") do |outFile|
    options[:output] = outFile
  end
  
  opt.on("-h","--help","help") do
    puts optparse
    Process.exit(0)
  end  
end
optparse.parse!
#
# basic checking
#
if options.size == 0 || ARGV.size != 1 then
  puts optparse
  Process.exit(0)
end
#
# setup params
#
result_mzid_file = ARGV[0]
tda_flag = true
outfile = options.has_key?(:output) ? options[:output] : (result_mzid_file.split(".mzid")[0] + ".csv")
#
# parse file and output
#
parser = MzID::ParserSax.new(result_mzid_file, (!options[:verbose] ? nil : true), tda_flag)
parser.write_to_csv(outfile, options[:mods])
