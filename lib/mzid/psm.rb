
module MzID
  #
  # class to represent a single peptide-spectrum match (PSM)
  #
  class PSM
    
    def initialize(h={})
      @id = h.has_key?(:id) ? h[:id] : nil
      @pep = h.has_key?(:pep) ? h[:pep] : nil
      @spec_prob = h.has_key?(:spec_prob) ? h[:spec_prob] : nil
      @peptide_ref= h.has_key?(:pep_ref) ? h[:pep_ref] : nil
      @spec_ref = h.has_key?(:spec_ref) ? h[:spec_ref] : nil
      @spec_num = h.has_key?(:spec_num) ? h[:spec_num] : nil
      @mods = h.has_key?(:mods) ? h[:mods] : nil
      @pep_evidence = h.has_key?(:pep_ev) ? h[:pep_ev] : nil
      @pass_thresh = h.has_key?(:pass_threshold) ? h[:pass_threshold] : nil
    end
    #
    #--
    # get methods
    #++
    #
    # get ID
    def get_id() @id end
    # get peptide sequence
    def get_pep() @pep end
    # get spectral probability
    def get_spec_prob() @spec_prob end
    # get peptide reference
    def get_pep_ref() @peptide_ref end
    # get spectrum reference
    def get_spec_ref() @spec_ref end
    # get spectrum number
    def get_spec_num() @spec_num end
    # get modifications
    def get_mods() @mods end
    # get peptide evidence
    def get_pep_ev() @pep_evidence end
    # get pass threshold flag
    def get_pass_threshold() @pass_thresh end
    #
    #--
    # set methods
    #++
    #
    # set the peptide sequence
    def set_pep(pep) @pep = pep end
    # set the spectral probability
    def set_spec_prob(prob) @spec_prob = prob end
    # set peptide
    def set_pep(pep_seq) @pep = pep_seq end
    # add the peptide evidence
    def add_pep_ev(pep_ev) @pep_evidence.nil? ? @pep_evidence = [pep_ev] : @pep_evidence.push(pep_ev) end    
    #
    # output PSM as string
    #
    def to_s() "[#{@spec_num}; Pep: #{@pep}; SpecProb: #{@spec_prob}; Mods #{@mods.to_s}]" end
  end

end
