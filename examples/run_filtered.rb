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

# start the daemon, and let us know the file to which it reports
#puts MemoryProfiler.start_daemon( :limit=>5, :delay=>10, :marshall_size=>true, :sort_by=>:absdelta )

#rpt  = MemoryProfiler.start( :limit=>10 ) do
  

# parser_s = MzID::BatchParser.new(ARGV[0])
# parser_s.each_spectrum do |psm_lst|
  
#   next if psm_lst.size == 1
  
#   puts psm_lst.to_s
#   Process.exit(0)
# end

require 'ruby-prof'


parser = MzID::FilteredStreamingParser.new(ARGV[0], 10**-10, true)
#parser.each_spectrum do |psm_lst|

#RubyProf.start  
CSV.open("result.csv", "w", {:col_sep => "\t"}) do |csv|
  csv << ["spec_num", "peptide", "spec_prob", "prot_ids"]

  parser.each_psm do |psm|
    pep_seq = psm.get_pep
    spec_num = psm.get_spec_num
    sp_prob = psm.get_spec_prob
    
    psm.get_pep_ev.each do |pepev| 
      prot_id = parser.get_prot_id(pepev) 
      
      csv << [spec_num, pep_seq, sp_prob, prot_id]
    end 
    
    #Process.exit(0)
  end 
  
end

#result=RubyProf.stop
#printer = RubyProf::FlatPrinter.new(result)
#printer.print(STDOUT)
