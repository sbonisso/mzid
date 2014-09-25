#!/usr/bin/env ruby

#
# compute some basic statistics on an mzid file:
# * peptides per spectrum
# * spectral count per peptide
# * distribution of number of mods
#

require 'mzid'

if !(ARGV[0] =~ /\.mzid$/) then
  puts "USAGE: #{__FILE__} results.mzid"
  Process.exit(0)
end

parser = MzID::Parser.new(ARGV[0])

pep_per_spec = []
spec_counts = Hash.new
pep_mod_count = []
parser.each_spectrum(true) do |psm_lst|
  
  pep_per_spec.push(psm_lst.size)
  
  psm_lst.each do |psm|
    # count spectra per pep
    pep = psm.get_pep
    spec_counts.has_key?(pep) ? spec_counts[pep] += 1 : spec_counts[pep] = 1
    # 
    mods = psm.get_mods
    pep_mod_count.push(mods.nil? ? 0 : mods.size)
  end
  
end
#
# crunch the lists into histogram
#
# peptides per spectrum
puts "peptides per spectrum"
puts ["num", "count"].join("\t")
pep_per_spec.uniq.sort.each{|v| puts [v, pep_per_spec.count(v)].join("\t")}
# 
# spectral count for each peptide
#spec_counts.sort_by{|a| a[1]}.each{|a| puts a.join("\t")}
#
# distribution of modifications per peptide
puts "distribution of mods per peptide"
puts ["num", "count"].join("\t")
pep_mod_count.uniq.sort.each{|v| puts [v, pep_mod_count.count(v)].join("\t")}