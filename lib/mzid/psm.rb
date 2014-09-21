
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
    end
    #
    # get methods
    #
    def get_id() @id end
    def get_pep() @pep end
    def get_spec_prob() @spec_prob end
    def get_pep_ref() @peptide_ref end
    def get_spec_ref() @spec_ref end
    #
    # output PSM as string
    #
    def to_s() "[#{@id}; Pep: #{@pep}; SpecProb: #{@spec_prob}]" end
  end

end
