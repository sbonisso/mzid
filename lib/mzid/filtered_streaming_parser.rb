require 'nokogiri'
require 'progressbar'
require 'mzid/base_parser'
require 'mzid/streaming_parser'

module MzID
  #
  # class to parse an mzIdentML file in a streaming (i.e., mem-efficient) manner
  # performs multi-pass filtering so that can maintain smallest datastruct in memory
  # 1) first collect counts of elements
  # 2) get list of peptide evidence from PSMs that pass filter
  # 3) 
  #
  class FilteredStreamingParser < StreamingParser
    
    def initialize(file, sp_thresh = 10.0**-10, use_pbar = nil)
      @num_spec = 0
      #
      @pep_ev_h_protID = Hash.new
      @pep_ev_h_startPos = Hash.new
      @pep_ev_h_endPos = Hash.new
      @pep_ev_h_dbseqRef = Hash.new
      super(file, use_pbar)
    end
    #
    #
    def cache_ids2(use_pbar = @use_pbar)
    end
    #
    # store peptide sequences in hash for lookup
    #
    def cache_ids(use_pbar = @use_pbar)
      num_pep, num_db_seq, num_pep_ev = get_num_elements(nil)
      puts "SPEC:\t#{@num_spec}"
      puts "PEP:\t#{num_pep}"
      puts "DB:\t#{num_db_seq}"
      puts "PEPEV:\t#{num_pep_ev}"

      pbar1 = ProgressBar.new("Caching psm", num_pep) if use_pbar
      reader = Nokogiri::XML::Reader(File.open(@mzid_file))
      reader.each do |node|
        
      end

      t1_pep = Time.now
      @pep_h = Hash.new
      @mod_h = Hash.new
      #pbar = ProgressBar.new("Caching", num_pep+num_db_seq+num_pep_ev) if use_pbar
      pbar1 = ProgressBar.new("Caching pep", num_pep) if use_pbar
      reader = Nokogiri::XML::Reader(File.open(@mzid_file))
      reader.each do |node|
        #
        if node.name == "Peptide" then
          #pbar.inc if use_pbar
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
      t2_pep = Time.now
      #
      # pbar2 = ProgressBar.new("Caching db", num_db_seq) if use_pbar
      # t1_db = Time.now
      # reader2 = Nokogiri::XML::Reader(File.open(@mzid_file))
      # reader2.each do |node|
      #   #
      #   if node.name == "DBSequence" then
      #     # parse local DBSequence entry
      #     tmp_node = Nokogiri::XML.parse(node.outer_xml)
      #     tmp_node.remove_namespaces!
      #     root = tmp_node.root
      #     cache_db_seq_entries(root)
      #     pbar2.inc if use_pbar
      #   end
      #   #
      #   # if node.name == "PeptideEvidence" then
      #   #   # parse local DBSequence entry
      #   #   tmp_node = Nokogiri::XML.parse(node.outer_xml)
      #   #   tmp_node.remove_namespaces!
      #   #   root = tmp_node.root
      #   #   cache_pep_ev(root)
      #   #   pbar.inc if use_pbar
      #   # end 

      # end
      # pbar2.finish if use_pbar
      # t2_db = Time.now
      # puts "TIME:\t#{t2_db-t1_pep}"
      # puts "TIME PER PEP:\t#{(t2_pep-t1_pep)/num_pep}"
      # puts "TIME PER DB:\t#{(t2_db-t1_db)/num_db_seq}"
      puts "PEP_H SIZE:\t#{@pep_h.size}"
      puts "DBSEQ_H SIZE:\t#{@db_seq_h.size}"
    end
    #
    # store database sequence entries (ids) 
    #
    def cache_db_seq_entries(root)
      dbseq_lst = root.xpath('//DBSequence')
      dbseq_lst.each do |dnode|
        id = dnode["id"].to_sym
        acc_id = dnode["accession"]
        @db_seq_h[id] = acc_id.to_sym
      end
    end 
    #
    # store peptide evidence sequences in hash for lookup
    #
    def cache_pep_ev(root)
      pep_ev_lst = root.xpath('//PeptideEvidence')
      pep_ev_lst.each do |pnode|
        id = pnode["id"]
        # @pep_ev_h[id] = 
        #   PeptideEvidence.new(#:id => pnode["id"],
        #                       :db_seq_ref => pnode["dBSequence_ref"],
        #                       #:pep_id => pnode["peptide_ref"],
        #                       :start_pos => pnode["start"].to_i,
        #                       :end_pos => pnode["end"].to_i,
        #                       #:pre => pnode["pre"],
        #                       #:post => pnode["post"],
        #                       :prot_id => @db_seq_h[pnode["dBSequence_ref"]].to_sym)
        
        @pep_ev_h_protID[id.to_sym] = @db_seq_h[pnode["dBSequence_ref"]].to_sym
        @pep_ev_h_startPos[id.to_sym] = pnode["start"].to_i,
        @pep_ev_h_endPos[id.to_sym] = pnode["end"].to_i
        @pep_ev_h_dbseqRef[id.to_sym] = pnode["dBSequence_ref"].to_sym
      end
    end
    #
    # given a xml node of a psm, return the PSM 
    #
    def get_psm(psm_node)
      # get peptide evidence list
      pep_ev_raw_lst = psm_node.xpath('.//PeptideEvidenceRef')
      pep_ev_lst = pep_ev_raw_lst.map{|penode| pep_ev_ref_id = penode["peptideEvidence_ref"].to_sym}
      # pep_ev_lst = pep_ev_raw_lst.map do |penode|
      #   pep_ev_ref_id = penode["peptideEvidence_ref"]
      #   puts "id:\t" + pep_ev_ref_id
      # #   #@db_seq_h[@pep_ev_h[pep_ev_ref_id]]  # if use simpler hash of prot ID
      # #   # @pep_ev_h[pep_ev_ref_id]  # if use PeptideEvidence object
      # end 
      # get cvparams
      cvlst = psm_node.xpath('.//cvParam')
      # find spectral prob
      tmp_lst = cvlst.select{|v| v['name'] == "MS-GF:SpecEValue"}
      spec_prob = tmp_lst[0]['value']
      # get peptide
      pep_seq = @pep_h[psm_node['peptide_ref'].to_sym]
      # get spectrum id/ref number
      spec_id = psm_node['id']
      spec_num = spec_id.split("_")[1].to_i
      spec_ref = spec_id.split("_")[-1].to_i
      #      
      # store in object
      psm = PSM.new(:spec_num => spec_num, 
                    :spec_ref => spec_ref, 
                    :pep => pep_seq, 
                    :spec_prob => spec_prob.to_f,
                    :mods => (@mod_h.has_key?(psm_node['peptide_ref']) ? @mod_h[psm_node['peptide_ref']] : nil),
                    :pep_ev => pep_ev_lst)
    end
    #
    # load PSMs into memory, and go back to perform lookup for prot ids
    #
    def write_to_file(outfile)
      
    end
    

  end

end