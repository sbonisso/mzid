module MzID
  #
  # class to represent peptide evidence entries in file
  #
  class PeptideEvidence
    def initialize(h={})
      @id = h.has_key?(:id) ? h[:id] : nil
      @db_seq_ref = h.has_key?(:db_seq_ref) ? h[:db_seq_ref] : nil
      @pep_id = h.has_key?(:pep_id) ? h[:pep_id] : nil
      @start_pos = h.has_key?(:start_pos) ? h[:start_pos] : nil
      @end_pos = h.has_key?(:end_pos) ? h[:end_pos] : nil
      @pre = h.has_key?(:pre) ? h[:pre] : nil
      @post = h.has_key?(:post) ? h[:post] : nil
      @is_decoy = h.has_key?(:is_decoy) ? h[:is_decoy] : nil
      @prot_id = h.has_key?(:prot_id) ? h[:prot_id] : nil
    end
    #
    # get methods
    #
    def get_id() @id end
    def get_db_seq_ref() @db_seq_ref end
    def get_pep_id() @pep_id end
    def get_start_pos() @start_pos end
    def get_end_pos() @end_pos end
    def get_pre() @pre end
    def get_post() @post end
    def get_is_decoy() @is_decoy end
    def get_prot_id() @prot_id end
    #
    # represent as string
    #
    def to_s() 
      "[#{@id}, #{@pep_id}; #{@start_pos}:#{@end_pos}, #{@pre}...#{@post}]" 
    end
    
  end

  
end
