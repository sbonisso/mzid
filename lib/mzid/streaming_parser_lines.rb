require 'nokogiri'
require 'progressbar'
require 'mzid/base_parser'
require 'mzid/streaming_parser'
require 'csv'

module MzID
  #
  # class to parse an mzIdentML file in a streaming (i.e., mem-efficient) manner
  # not using any XML parsing library, only exploiting the structure of mzIdentML files
  #
  class StreamingParserLines < StreamingParser
    
    def initialize(file, sp_thresh = 10.0**-10, use_pbar = nil, tda_flag = true)
      @num_spec = 0
      @tda_flag = tda_flag
      #
      @pep_ev_h_protID = Hash.new
      @pep_ev_h_startPos = Hash.new
      @pep_ev_h_endPos = Hash.new
      @pep_ev_h_dbseqRef = Hash.new
      super(file, use_pbar)
    end
    #
    # get a protein ID from a PeptideEvidenceID
    #
    def get_prot_id(pep_ev_id) 
      #dbref = @pep_ev_h_dbseqRef[pep_ev_id]
      dbref = @pep_ev_h[pep_ev_id].get_db_seq_ref
      prot_id = @db_seq_h[dbref]
      prot_id
    end 
    #
    #
    #
    def get_pep_start(pep_ev_id) @pep_ev_h[pep_ev_id].get_start_pos end
    def get_pep_end(pep_ev_id) @pep_ev_h[pep_ev_id].get_end_pos end
    def get_is_decoy(pep_ev_id) @pep_ev_h[pep_ev_id].get_is_decoy end
    #attr_accessor :pep_ev_h_dbseqRef
    
    #
    # store peptide sequences in hash for lookup
    #
    def cache_ids(use_pbar = @use_pbar)
      num_pep, num_db_seq, num_pep_ev = get_num_elements(nil)
      
      @pep_h = Hash.new
      @mod_h = Hash.new
      pbar1 = ProgressBar.new("peptides", num_pep/2) if use_pbar
      reader = Nokogiri::XML::Reader(File.open(@mzid_file))
      reader.each do |node|
        # parse Peptide items
        if node.name == "Peptide" then
          # parse local peptide entry
          tmp_node = Nokogiri::XML.parse(node.outer_xml)
          tmp_node.remove_namespaces!
          root = tmp_node.root          
          pep_id = root["id"].to_sym
          # skip if already handled PepID
          next if @pep_h.has_key?(pep_id)
          # parse sequence/mods if haven't seen it yet
          pep_seq = get_peptide_sequence(root)
          mod_line = get_modifications(root)
          @pep_h[pep_id] = pep_seq
          @mod_h[pep_id] = mod_line
          pbar1.inc if use_pbar
        end
      end
      pbar1.finish if use_pbar
      # now parse DBSequence items
      dbseq_re = Regexp.new(/^\s*<DBSequence\s/)
      pbar2 = ProgressBar.new("db_seq", num_db_seq) if use_pbar
      IO.foreach(@mzid_file) do |line|
        next if !dbseq_re.match(line)
        
        prot_id = line.match(/accession=\"([\w|\|]+)/)[1]
        db_id = line.match(/id=\"(\w+)/)[1]
        
        @db_seq_h[db_id.to_sym] = prot_id.to_sym
        pbar2.inc if use_pbar
      end
      pbar2.finish if use_pbar
      # now parse PeptideEvidence items
      pepev_re = Regexp.new(/^\s*<PeptideEvidence\s/)
      pbar3 = ProgressBar.new("pep_ev", num_pep_ev) if use_pbar
      IO.foreach(@mzid_file) do |line|
        next if !pepev_re.match(line)
        
        db_id = line.match(/dBSequence_ref=\"(\w+)/)[1]
        start_pos = line.match(/start=\"(\d+)/)[1].to_i
        end_pos = line.match(/end=\"(\d+)/)[1].to_i
        pep_ev = line.match(/id=\"(\w+)/)[1]
        is_decoy = line.match(/isDecoy=\"(\w+)\"/)[1]
        # @pep_ev_h_dbseqRef[pep_ev.to_sym] = db_id.to_sym
        @pep_ev_h[pep_ev.to_sym] = PeptideEvidence.new(:db_seq_ref => db_id.to_sym,
                                                       :start_pos => start_pos,
                                                       :end_pos => end_pos,
                                                       :is_decoy => is_decoy)
        pbar3.inc if use_pbar
      end
      pbar3.finish if use_pbar      
    end    
    #
    # iterate through each psm by identifying them parsing the file 
    # one line at a time - faster than using XML parser
    #
    def each_psm(use_pbar=@use_pbar)     
      num_lines = `wc -l #{@mzid_file}`.to_i if use_pbar
      curr_psm = nil
      pbar = ProgressBar.new("PSMs", num_lines) if use_pbar
      specid_item_re = Regexp.new(/^\s+<SpectrumIdentificationItem\s/)
      pepevref_re = Regexp.new(/^\s+<PeptideEvidenceRef\s/)
      specprob_re = Regexp.new(/name=\"MS-GF:SpecEValue\"\/>$/)
      specid_item_end_re = Regexp.new(/^\s+<\/SpectrumIdentificationItem>\s*$/)
      IO.foreach(@mzid_file) do |line|
        pbar.inc if use_pbar
        # skip line if not one pertaiing to spectrum ID item
        next if !specid_item_re.match(line) &&
          !pepevref_re.match(line) &&
          !specprob_re.match(line) &&
          !specid_item_end_re.match(line)
        # beginning of spectrum ID item
        if specid_item_re.match(line) then
          spec_id_id = line.match(/id=\"(\w+)/)[1]
          spec_num = spec_id_id.split("_")[1].to_i
          pep_ref = line.match(/peptide_ref=\"(\w+)/)[1]
          # get peptide
          pep_seq = @pep_h[pep_ref.to_sym]
          curr_psm = PSM.new(:spec_num => spec_num, :pep => pep_seq)
        elsif pepevref_re.match(line) then
          pep_ev = line.match(/peptideEvidence_ref=\"(\w+)/)[1]
          curr_psm.add_pep_ev(pep_ev.to_sym) if curr_psm
        elsif specprob_re.match(line) then
          sprob = line.match(/value=\"([\d|\w|\.|-]+)\"/)[1]
          curr_psm.set_spec_prob(sprob.to_f) if curr_psm
        elsif specid_item_end_re.match(line) then
          yield curr_psm
          curr_psm = nil # kill current PSM object 
        end        
      end
      pbar.finish if use_pbar
    end   
    #
    # load PSMs into memory, and go back to perform lookup for prot ids
    #
    def write_to_csv(outfile="result.csv", use_pbar=@use_pbar)
      CSV.open(outfile, "w", {:col_sep => "\t"}) do |csv|
        headerAry = ["#spec_num", "peptide", "spec_prob", "decoy", "prot_ids", "start", "end", "num_prot"]
        headerAry.delete("decoy") if !@tda_flag
        csv << headerAry
        
        # each PSM
        self.each_psm do |psm|
          pep_seq = psm.get_pep
          spec_num = psm.get_spec_num
          sp_prob = psm.get_spec_prob
          pass_thresh = psm.get_pass_threshold
          pep_ev_ref_lst = psm.get_pep_ev
          # number of proteins with matching peptide
          num_prot = pep_ev_ref_lst.size
          # for each PeptideEvidence, write a different line
          pep_ev_ref_lst.each do |pepev| 
            prot_id = self.get_prot_id(pepev)             
            start_pos = self.get_pep_start(pepev)
            end_pos = self.get_pep_end(pepev)
            is_decoy = self.get_is_decoy(pepev)
            ary = [spec_num, pep_seq, sp_prob, is_decoy, prot_id, start_pos, end_pos, num_prot]
            ary.delete_at(3) if !@tda_flag
            csv << ary
          end 
        end 
      end
    end
    

  end

end
