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
require 'memory-profiler'

if !(ARGV[0] =~ /\.mzid$/) then
  puts "USAGE: #{__FILE__} results.mzid"
  Process.exit(0)
end

# start the daemon, and let us know the file to which it reports
#puts MemoryProfiler.start_daemon( :limit=>5, :delay=>10, :marshall_size=>true, :sort_by=>:absdelta )

#rpt  = MemoryProfiler.start( :limit=>10 ) do
  
parser = MzID::FilteredStreamingParser.new(ARGV[0], 10**-10, nil)
#parser.each_spectrum do |psm_lst|
  
parser.each_psm do |psm|

  puts psm.to_s
  puts psm.get_pep_ev.to_s
  Process.exit(0)

end

#end

#puts MemoryProfiler.format(rpt)

#MemoryProfiler.stop_daemon

