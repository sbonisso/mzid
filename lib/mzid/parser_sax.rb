require 'ox'
require 'progressbar'
require 'csv'

module MzID
  #
  # class to parse an mzIdentML file
  #
  class ParserSax
    #
    # counts the different element types
    #
    class CounterHandler < Ox::Sax
      ATTR = [:DBSequence, :Peptide, :PeptideEvidence, :SpectrumIdentificationItem]
      #
      def initialize()
        @dbseq_count = 0
        @pep_count = 0
        @pepev_count = 0
        @spec_count = 0
      end
      attr_accessor :dbseq_count, :pep_count, :pepev_count, :spec_count
      #
      def start_element(name)
        return unless ATTR.include?(name)
        case name
        when :DBSequence 
          @dbseq_count += 1 
        when :Peptide 
          @pep_count += 1
        when :PeptideEvidence 
          @pepev_count += 1 
        when :SpectrumIdentificationItem 
          @spec_count += 1
        end 
      end 
    end 
    #
    # handler for DBSequence elements
    #
    class DBSequenceHandler < Ox::Sax
      ATTR = [:DBSequence]
      #
      def initialize(num_dbseq=nil)
        @dbseq_h = Hash.new
        @pbar = num_dbseq.nil? ? nil : ProgressBar.new("DBSeq", num_dbseq)
      end 
      #
      attr_accessor :dbseq_h, :pbar
      #
      def start_element(name)
        @h = {} if name == :DBSequence
        @curr_node = name
      end
      #
      def attr(name, value)
        return unless ATTR.include?(@curr_node)
        @h[name] = value if name == :accession || name == :id
      end
      #
      def value(value)
        return unless ATTR.include?(@curr_node)
      end 
      #
      def end_element(name)
        return unless name == :DBSequence
        @pbar.inc if !@pbar.nil?
        @dbseq_h[@h[:id].to_sym] = @h[:accession]
      end 
    end
    #
    # handler for Peptide elements
    #
    class PeptideHandler < Ox::Sax
      ATTR = [:Peptide, :PeptideSequence]
      
      def initialize(num_pep=nil)
        @pbar = num_pep.nil? ? nil : ProgressBar.new("Peptides", num_pep)
        @pep_h = Hash.new
      end 

      attr_accessor :pep_h, :pbar
      #
      def start_element(name)
        @h = {} if name == :Peptide
        @curr_node = name
      end
      #
      def attr(name, value)
        return unless ATTR.include?(@curr_node)
        @h[name] = value
      end
      #
      def text(value)
        return unless ATTR.include?(@curr_node)
        @h[@curr_node] = value
      end 
      #
      def end_element(name)
        return unless name == :Peptide
        @pbar.inc if !@pbar.nil?
        @pep_h[@h[:id].to_sym] = @h[:PeptideSequence]
      end 
    end
    #
    # handler for PeptideEvent elements
    #
    class PeptideEventHandler < Ox::Sax
      ATTR_MAP = [:post, :pre, :start, :end, :peptide_ref, :dBSequence_ref, :id]
      ATTR = [:PeptideEvidence]
      def initialize(dbseq_h, num_pepev=nil)
        @dbseq_h = dbseq_h
        @pep_ev_h = Hash.new
        @pbar = num_pepev.nil? ? nil : ProgressBar.new("PepEv", num_pepev)
      end 
      
      attr_accessor :pep_ev_h, :pbar
      
      def start_element(name)
        @h = {} if name == :PeptideEvidence
        @curr_node = name
      end

      def attr(name, value)
        return unless ATTR.include?(@curr_node)
        @h[name] = value if ATTR_MAP.include?(name)
      end
      
      def end_element(name)
        return unless name == :PeptideEvidence
        @pbar.inc if !@pbar.nil?
        @pep_ev_h[@h[:id].to_sym] =  
          PeptideEvidence.new(:db_seq_ref => @h[:dBSequence_ref].to_sym,
                              :pep_id => @h[:peptide_ref].to_sym,
                              :start_pos => @h[:start],
                              :end_pos => @h[:end],
                              :prot_id => @dbseq_h[@h[:dBSequence_ref].to_sym])
      end 

    end 
    #
    # handler for SpectrumIDItem elements
    #
    class SpectraIDHandler < Ox::Sax
      ATTR = [:SpectrumIdentificationItem, :PeptideEvidenceRef]  
      SPEC_ATTR_MAP = [:peptide_ref, :id]
      SPEC_PROB_ATTR_MAP = [:accession, :value]
      SPEC_PROB_ACC = "MS:1002052"  # code for spec-prob
      def initialize(dbseq_h, pep_h, pep_ev_h, block, num_spec=nil)
        @yield_to = block
        @dbseq_h = dbseq_h
        @pep_h = pep_h
        @pep_ev_h = pep_ev_h
        @spec_h = Hash.new
        @pbar = num_spec.nil? ? nil : ProgressBar.new("Spectra", num_spec)
      end 

      attr_accessor :spec_h, :pbar

      def start_element(name)
        @h = {} if name == :SpectrumIdentificationItem
        @curr_node = name
        @h_param = nil if name == :cvParam
      end

      def attr(name, value)
        return unless ATTR.include?(@curr_node) || 
          (@curr_node == :cvParam && SPEC_PROB_ATTR_MAP.include?(name))
        
        @h_param[name] = value if !@h_param.nil?
        @h_param = {} if name == :accession && value == SPEC_PROB_ACC    
        if name == :peptideEvidence_ref then # if peptideEvidence, force into list
          @h[name].nil? ? @h[name] = [value.to_sym] : @h[name].push(value.to_sym)
        end 
        @h[name] = value.to_sym if SPEC_ATTR_MAP.include?(name)
        @h[name] = value.split("_")[1].to_i if name == :id
      end
      
      def attrs_done()
        return unless (!@h_param.nil? && !@h.nil?)
        @h[:spec_prob] = @h_param[:value].to_f 
      end 
      
      def end_element(name)
        return unless name == :SpectrumIdentificationItem
        @yield_to.call(@h)
        @pbar.inc if !@pbar.nil?
      end 
    end
    
    def initialize(file, use_pbar = nil)
      @use_pbar = use_pbar
      @mzid_file = file
      #
      # get counts
      if @use_pbar then
        count_handler = CounterHandler.new
        File.open(@mzid_file){|f| Ox.sax_parse(count_handler, f)}     
        @num_spec = count_handler.spec_count
      end 
      
      #puts "DBSeq:\t#{count_handler.dbseq_count}"
      #puts "Peptides:\t#{count_handler.pep_count}"
      #puts "PepEv:\t#{count_handler.pepev_count}"
      #puts "Spectra:\t#{count_handler.spec_count}"
      #
      # cache DBSequence elements
      dbseq_handler = DBSequenceHandler.new(@use_pbar.nil? ? nil : count_handler.dbseq_count)
      File.open(@mzid_file){|f| Ox.sax_parse(dbseq_handler, f)}
      dbseq_handler.pbar.finish if !dbseq_handler.pbar.nil?
      @dbseq_h = dbseq_handler.dbseq_h
      #      
      # cache Peptide elements
      pep_handler = PeptideHandler.new(@use_pbar.nil? ? nil : count_handler.pep_count)
      File.open(@mzid_file){|f| Ox.sax_parse(pep_handler, f)}
      pep_handler.pbar.finish if !pep_handler.pbar.nil?
      @pep_h = pep_handler.pep_h
      #
      # create/cache PeptideEvent elements
      pep_ev_handler = PeptideEventHandler.new(@dbseq_h, @use_pbar.nil? ? nil : count_handler.pepev_count)
      File.open(@mzid_file){|f| Ox.sax_parse(pep_ev_handler, f)}
      pep_ev_handler.pbar.finish if !pep_ev_handler.pbar.nil?
      @pep_ev_h = pep_ev_handler.pep_ev_h
      
    end
    #
    # write output to csv
    #
    def write_to_csv(outfile="result.csv", num_spec=nil)
      CSV.open(outfile, "w", {:col_sep => "\t"}) do |csv|
        csv << ["#spec_num", "peptide", "spec_prob", "prot_ids", "start", "end", "num_prot"]
        
        proc = Proc.new do |spec_h|
          # peptide reference/seq
          pep_ref = spec_h[:peptide_ref].to_sym
          pep_seq = @pep_h[pep_ref]
          # peptide evidence list
          pep_ev_ref_lst = spec_h[:peptideEvidence_ref]
          # number of proteins with matching peptide
          num_prot = pep_ev_ref_lst.size
          # for each PeptideEvidence entry ...
          pep_ev_ref_lst.each do |pep_ev_ref|
            pep_ev = @pep_ev_h[pep_ev_ref]
            # start/end pos within protein
            start_pos = pep_ev.get_start_pos
            end_pos = pep_ev.get_end_pos
            # get protein ID
            prot_id = pep_ev.get_prot_id
            # write to file
            csv << [spec_h[:id], pep_seq, spec_h[:spec_prob], prot_id, start_pos, end_pos, num_prot]
          end 
          
        end
        spec_handler = SpectraIDHandler.new(@dbseq_h, @pep_h, @pep_ev_h, proc, @use_pbar.nil? ? nil : @num_spec)
        File.open(@mzid_file){|f| Ox.sax_parse(spec_handler, f)}
        spec_handler.pbar.finish if !spec_handler.pbar.nil?
      end
    end
    
  end
  
end
