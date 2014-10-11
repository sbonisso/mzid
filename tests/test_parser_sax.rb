require_relative 'load_helper'
require_relative 'test_helper'

require 'mzid'
require 'tempfile'

class TestParserSax < MiniTest::Test   
  #
  # test very simple output to csv method
  #
  def test_write_to_csv()
    exp_prot_id_lst = ["sp|Q9RXK5|EFG_DEIRA"]
    infile = "#{File.dirname(__FILE__)}/data/example.mzid"
    p1 = MzID::ParserSax.new(infile, nil)
    tmp = Tempfile.new("results")
    p1.write_to_csv(tmp.path)
    tmp.close
    # read in output lines
    lines = IO.readlines(tmp.path)
    # expected
    exp_out = ["spec_num\tpeptide\tspec_prob\tprot_ids\tstart\tend\tnum_prot\n", "3591\tVVIYDGSYHEVDSSEMAFK\t1.6364497e-26\tsp|Q9RXK5|EFG_DEIRA\t573\t591\t1\n"]
    # test 
    assert_equal(exp_out, lines, "unexpected output file contents")
  end
  
end
