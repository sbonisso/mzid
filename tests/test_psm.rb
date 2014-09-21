require_relative 'load_helper'
require_relative 'test_helper'

require 'mzid'

class TestPSM < MiniTest::Test

  def test_basic_psm()
    p1 = MzID::PSM.new(:id => "sp1", :pep => "ACDEF")
    assert_equal("sp1", p1.get_id, "unexpected ID")
    assert_equal("ACDEF", p1.get_pep, "unexpected peptide")
  end

  
end
