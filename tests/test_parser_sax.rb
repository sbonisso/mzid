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
    p1 = MzID::ParserSax.new(infile, nil, false)
    tmp = Tempfile.new("results")
    p1.write_to_csv(tmp.path, false)
    tmp.close
    # read in output lines
    lines = IO.readlines(tmp.path)
    # expected
    exp_out = ["#spec_num\tpeptide\tspec_prob\tprot_ids\tstart\tend\tnum_prot\n", "3591\tVVIYDGSYHEVDSSEMAFK\t1.6364497e-26\tsp|Q9RXK5|EFG_DEIRA\t573\t591\t1\n"]
    # test 
    assert_equal(exp_out, lines, "unexpected output file contents")
  end

  #
  # test very simple output to csv method
  #
  def test_mods_write_to_csv()
    exp_prot_id_lst = ["sp|Q9RXK5|EFG_DEIRA"]
    infile = "#{File.dirname(__FILE__)}/data/example_mod.mzid"
    p1 = MzID::ParserSax.new(infile, nil, false)
    tmp = Tempfile.new("results")
    p1.write_to_csv(tmp.path)
    tmp.close
    # read in output lines
    lines = IO.readlines(tmp.path)
    # expected
    exp_out = ["#spec_num\tpeptide\tspec_prob\tprot_ids\tstart\tend\tnum_prot\tmods\n",
               "3591\tVVIYDGSYHEVDSSEMAFK\t1.6364497e-26\tsp|Q9RXK5|EFG_DEIRA\t573\t591\t1\t\n",
               "8578\tRFQIGEVVLEGTGECHPCSR\t3.9070557e-05\ttr|Q9RXN7|Q9RXN7_DEIRA\t132\t151\t1\t15;+57|18;+57\n",
               "8578\tFFHWEGRERHEFGFFFR\t3.9070557e-05\ttr|Q9RS55|Q9RS55_DEIRA\t99\t115\t1\t\n"]
    # test 
    assert_equal(exp_out, lines, "unexpected output file contents")
  end
  
end
