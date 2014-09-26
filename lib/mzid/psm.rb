
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
    end
    #
    # get methods
    #
    def get_id() @id end
    def get_pep() @pep end
    def get_spec_prob() @spec_prob end
    def get_pep_ref() @peptide_ref end
    def get_spec_ref() @spec_ref end
    def get_spec_num() @spec_num end
    def get_mods() @mods end
    def get_pep_ev() @pep_evidence end
    #
    # output PSM as string
    #
    def to_s() "[#{@spec_num}; Pep: #{@pep}; SpecProb: #{@spec_prob}; Mods #{@mods.to_s}]" end
  end

end
