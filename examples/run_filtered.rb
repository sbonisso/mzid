#!/usr/bin/env ruby

#
# compute some basic statistics on an mzid file:
# * peptides per spectrum
# * spectral count per peptide
# * distribution of number of mods
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib/")

require 'mzid'
require 'csv'
#require 'memory-profiler'

if !(ARGV[0] =~ /\.mzid$/) then
  puts "USAGE: #{__FILE__} results.mzid"
  Process.exit(0)
end


parser = MzID::StreamingParserLines.new(ARGV[0], 10**-10, true)

parser.write_to_csv("result.csv")

# CSV.open("result.csv", "w", {:col_sep => "\t"}) do |csv|
#   csv << ["spec_num", "peptide", "spec_prob", "prot_ids"]
# 
#   parser.each_psm do |psm|
#     pep_seq = psm.get_pep
#     spec_num = psm.get_spec_num
#     sp_prob = psm.get_spec_prob
#    
#     psm.get_pep_ev.each do |pepev| 
#       prot_id = parser.get_prot_id(pepev) 
#      
#       csv << [spec_num, pep_seq, sp_prob, prot_id]
#     end 
#   end 
# end
