require 'nokogiri'
require 'progressbar'
require 'mzid/base_parser'
require 'mzid/streaming_parser'

module MzID
  #
  # class to parse an mzIdentML file in a streaming (i.e., mem-efficient) manner
  # not using any XML parsing library, only exploiting the structure of mzIdentML files
  #
  class StreamingParserLines < StreamingParser
    
    def initialize(file, sp_thresh = 10.0**-10, use_pbar = nil)
      @num_spec = 0
      #
      @pep_ev_h_protID = Hash.new
      @pep_ev_h_startPos = Hash.new
      @pep_ev_h_endPos = Hash.new
      @pep_ev_h_dbseqRef = Hash.new
      super(file, use_pbar)
    end
    
    def get_prot_id(pep_ev_id) 
      dbref = @pep_ev_h_dbseqRef[pep_ev_id]
      prot_id = @db_seq_h[dbref]
      prot_id
    end 
    
    attr_accessor :pep_ev_h_dbseqRef

    #
    # store peptide sequences in hash for lookup
    #
    def cache_ids(use_pbar = @use_pbar)
      num_pep, num_db_seq, num_pep_ev = get_num_elements(nil)
      puts "SPEC:\t#{@num_spec}"
      puts "PEP:\t#{num_pep}"
      puts "DB:\t#{num_db_seq}"
      puts "PEPEV:\t#{num_pep_ev}"

      #pbar1 = ProgressBar.new("Caching psm", num_pep) if use_pbar
      #reader = Nokogiri::XML::Reader(File.open(@mzid_file))
      #reader.each do |node|        
      #end

      @pep_h = Hash.new
      @mod_h = Hash.new
      #pbar = ProgressBar.new("Caching", num_pep+num_db_seq+num_pep_ev) if use_pbar
      pbar1 = ProgressBar.new("peptides", num_pep/2) if use_pbar
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
      #
      pbar2 = ProgressBar.new("db_seq", num_db_seq) if use_pbar
      IO.foreach(@mzid_file) do |line|
        next if !line.match(/^\s+<DBSequence\s/)
        
        prot_id = line.match(/accession=\"([\w|\|]+)/)[1]
        db_id = line.match(/id=\"(\w+)/)[1]
        
        @db_seq_h[db_id.to_sym] = prot_id.to_sym
        pbar2.inc if use_pbar
      end
      pbar2.finish if use_pbar
      #
      pbar3 = ProgressBar.new("pep_ev", num_pep_ev) if use_pbar
      IO.foreach(@mzid_file) do |line|
        next if !line.match(/^\s+<PeptideEvidence\s/)
        
        db_id = line.match(/dBSequence_ref=\"(\w+)/)[1]
        pep_ev = line.match(/id=\"(\w+)/)[1]
        @pep_ev_h_dbseqRef[pep_ev.to_sym] = db_id.to_sym
        pbar3.inc if use_pbar
      end
      pbar3.finish if use_pbar
      #
      puts "PEP_H SIZE:\t#{@pep_h.size}"
      puts "DBSEQ_H SIZE:\t#{@db_seq_h.size}"
      puts "PEP_EV_H SIZE:\t#{@pep_ev_h_dbseqRef.size}"
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
        id = pnode["id"].to_sym
        
        # @pep_ev_h_protID[id.to_sym] = @db_seq_h[pnode["dBSequence_ref"]].to_sym
        # @pep_ev_h_startPos[id.to_sym] = pnode["start"].to_i,
        # @pep_ev_h_endPos[id.to_sym] = pnode["end"].to_i
        @pep_ev_h_dbseqRef[id.to_sym] = pnode["dBSequence_ref"].to_sym
      end
    end   
    #
    # iterate through each psm
    #
    def each_psm(use_pbar=@use_pbar)
      # hit_values = File.open(@mzid_file) do |io|
      #   doc = Nokogiri::XML.parse(io, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::STRICT)
      #   doc.remove_namespaces!
      #   root = doc.root
      #   # get list of identifications
      #   spec_results = root.xpath('//SpectrumIdentificationResult')
      #   pbar = ProgressBar.new("PSMs", spec_results.size) if use_pbar
      #   spec_results.each do |sres|
      #     # 
      #     psms_of_spec = sres.xpath('.//SpectrumIdentificationItem')
      #     # go over each PSM from the spectra
      #     psms_of_spec.each do |psm_node|
      #       psm = get_psm(psm_node)
      #       # yield psm object
      #       yield psm
      #     end
      #     pbar.inc if use_pbar
      #   end
      #   pbar.finish if use_pbar
      # end
      num_lines = `wc -l #{@mzid_file}`.to_i if use_pbar
      curr_psm = nil
      pbar = ProgressBar.new("PSMs", num_lines) if use_pbar
      IO.foreach(@mzid_file) do |line|
        pbar.inc if use_pbar
        next if !line.match(/^\s+<SpectrumIdentificationItem\s/) &&
          !line.match(/^\s+<PeptideEvidenceRef\s/) && 
          !line.match(/name=\"MS-GF:SpecEValue\"\/>$/) &&
          !line.match(/^\s+<\/SpectrumIdentificationItem>\s*$/)
        
        if line.match(/^\s+<SpectrumIdentificationItem\s/) then
          #puts 'spec item'
          spec_id_id = line.match(/id=\"(\w+)/)[1]
          spec_num = spec_id_id.split("_")[1].to_i
          pep_ref = line.match(/peptide_ref=\"(\w+)/)[1]
          # get peptide
          pep_seq = @pep_h[pep_ref.to_sym]
          curr_psm = PSM.new(:spec_num => spec_num, :pep => pep_seq)
        elsif line.match(/^\s+<PeptideEvidenceRef\s/)  then
          #puts 'pep ev'
          pep_ev = line.match(/peptideEvidence_ref=\"(\w+)/)[1]
          curr_psm.add_pep_ev(pep_ev.to_sym) if curr_psm
        elsif line.match(/name=\"MS-GF:SpecEValue\"\/>$/) then
          #puts 'spec prob'
          sprob = line.match(/value=\"([\d|\w|\.|-]+)\"/)[1]
          curr_psm.set_spec_prob(sprob.to_f) if curr_psm
        elsif line.match(/^\s+<\/SpectrumIdentificationItem>\s*$/)
          #puts 'end'
          yield curr_psm
          curr_psm = nil # kill current PSM object 
        end        
      end
      pbar.finish if use_pbar
    end
    #
    # given a xml node of a psm, return the PSM 
    #
    def get_psm(psm_node)
      # get peptide evidence list
      pep_ev_raw_lst = psm_node.xpath('.//PeptideEvidenceRef')
      pep_ev_lst = pep_ev_raw_lst.map{|penode| pep_ev_ref_id = penode["peptideEvidence_ref"].to_sym}     
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
    def write_to_file(outfile, use_pbar=@use_pbar)
      
      pbar3 = ProgressBar.new("Caching pep_ev", num_db_seq) if use_pbar
      t1_db = Time.now
      reader3 = Nokogiri::XML::Reader(File.open(@mzid_file))
      reader3.each do |node|
        if node.name == "PeptideEvidence" then
          # parse local DBSequence entry
          tmp_node = Nokogiri::XML.parse(node.outer_xml)
          tmp_node.remove_namespaces!
          root = tmp_node.root
          #cache_pep_ev(root)
          pep_ev_lst = root.xpath('//PeptideEvidence')
          pep_ev_lst.each do |pnode|
            id = pnode["id"]
            start_pos = pnode["start"].to_i,
            end_pos = pnode["end"].to_i
            db_seq_ref = pnode["dBSequence_ref"].to_sym
          end 
          pbar3.inc if use_pbar
        end 
        
      end
      pbar3.finish if use_pbar

    end
    

  end

end
