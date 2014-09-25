require_relative 'load_helper'
require_relative 'test_helper'

require 'mzid'

class TestBatchParser < MiniTest::Test
  #
  # test the psm output of a very small mzid file
  #
  def test_basic_parser()
    infile = "#{File.dirname(__FILE__)}/data/example.mzid"
    p1 = MzID::BatchParser.new(infile)
    p1.each_psm do |spec_id|
      assert_equal(3591, spec_id.get_spec_num, "unexpected spec num")
      assert_equal("VVIYDGSYHEVDSSEMAFK", spec_id.get_pep, "unexpected peptide")
      assert_equal(1.6364497E-26, spec_id.get_spec_prob, "unexpected spectral probability")
    end
  end
  #
  # test the each_spectrum block
  #
  def test_per_spectrum()
    infile = "#{File.dirname(__FILE__)}/data/example.mzid"
    p1 = MzID::BatchParser.new(infile)
    p1.each_spectrum do |psm_lst|
      assert_equal(1, psm_lst.size, "unexpected list size")
    end
  end
  #
  # test the each_spectrum block on multiple result example
  #
  def test_per_spectrum_multiple()
    infile = "#{File.dirname(__FILE__)}/data/example_2.mzid"
    p1 = MzID::BatchParser.new(infile)
    i = 0
    size_lst = [1,4]
    num_lst = [3591, 6065]
    spec_probs = [[1.6364497E-26], [3.9093196E-5, 3.9093196E-5, 3.9093196E-5, 3.9093196E-5]]

    p1.each_spectrum do |psm_lst|
      #test fo spectrum number
      assert_equal(size_lst[i], psm_lst.size, "unexpected number of PSMs for spectrum #{num_lst[i]}")
      # test each PSM of spectrum
      psm_lst.each_with_index do |psm,j| 
        assert_equal(num_lst[i], psm.get_spec_num, "unexpected spectrum number for spectrum #{num_lst[i]}")
        assert_in_epsilon(spec_probs[i][j].to_f, psm.get_spec_prob.to_f, 0.001, "unexpected spectral prob")
      end
      i += 1
    end
  end
  #
  # test parsing of modifications
  #
  def test_modifications()
    infile = "#{File.dirname(__FILE__)}/data/example_mod.mzid"
    p1 = MzID::BatchParser.new(infile)
    mod_locs = [nil, [14,17], nil]
    mod_vals = [nil, [57.021463735,57.021463735], nil]
    i = 0
    p1.each_psm do |psm|
      modh = psm.get_mods
      if modh.nil? then
        assert_equal(mod_locs[i], nil, "expected non-nil mod hash")
      else
        assert_equal(mod_locs[i], modh.keys, "expected different locations")
        assert_equal(mod_vals[i], modh.values, "expected different mass deltas")
      end
      i += 1
    end
  end
  
end
