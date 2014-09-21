require_relative 'load_helper'
require_relative 'test_helper'

require 'mzid'

class TestParser < MiniTest::Test

  def test_basic_parser()
    infile = "#{File.dirname(__FILE__)}/data/example.mzid"
    p1 = MzID::Parser.new(infile)
    p1.each_psm do |spec_id|
      assert_equal("SII_3591_1", spec_id.get_id, "unexpected ID")
      assert_equal("VVIYDGSYHEVDSSEMAFK", spec_id.get_pep, "unexpected peptide")
      assert_equal("1.6364497E-26", spec_id.get_spec_prob, "unexpected spectral probability")
    end
  end

  
end
