require 'nokogiri'
require 'progressbar'
require 'mzid/base_parser'
require 'mzid/batch_parser'

module MzID
  #
  # class to parse an mzIdentML file in a streaming (i.e., mem-efficient) manner
  #
  class StreamingParser < BatchParser
    
    def initialize(file)
      @num_spec = 0
      super(file)
    end
    #
    # store peptide sequences in hash for lookup
    #
    def cache_ids()
      @pep_h = Hash.new
      @mod_h = Hash.new
      reader = Nokogiri::XML::Reader(File.open(@mzid_file))
      reader.each do |node|
        @num_spec += 1 if node.name == "SpectrumIdentificationResult"
        
        if node.name == "Peptide" then
          # parse local peptide entry
          tmp_node = Nokogiri::XML.parse(node.outer_xml)
          tmp_node.remove_namespaces!
          root = tmp_node.root
          
          pep_id = root["id"]
          # skip if already handled PepID
          next if @pep_h.has_key?(pep_id)
          # parse sequence/mods if haven't seen it yet
          pep_seq = get_peptide_sequence(root)
          mod_line = get_modifications(root)
          @pep_h[pep_id] = pep_seq 
          @mod_h[pep_id] = mod_line 
        end
        #
        if node.name == "DBSequence" then
          # parse local DBSequence entry
          tmp_node = Nokogiri::XML.parse(node.outer_xml)
          tmp_node.remove_namespaces!
          root = tmp_node.root
          cache_db_seq_entries(root)
        end
        #
        if node.name == "PeptideEvidence" then
          # parse local DBSequence entry
          tmp_node = Nokogiri::XML.parse(node.outer_xml)
          tmp_node.remove_namespaces!
          root = tmp_node.root
          cache_pep_ev(root)
        end 

      end
    end
    #
    # iterate through each psm
    #
    def each_psm(use_pbar=nil)
      reader = Nokogiri::XML::Reader(File.open(@mzid_file))
      pbar = ProgressBar.new("PSMs", @num_spec) if use_pbar
      reader.each do |node|
        next if node.name != "SpectrumIdentificationResult"        
        # parse local spec result entry
        tmp_node = Nokogiri::XML.parse(node.outer_xml)
        tmp_node.remove_namespaces!
        root = tmp_node.root
        # parse spectrum id item
        psms_of_spec = root.xpath('.//SpectrumIdentificationItem')
        psms_of_spec.each do |psm_node|
          # get peptide evidence list
          pep_ev_raw_lst = psm_node.xpath('.//PeptideEvidenceRef')
          pep_ev_lst = pep_ev_raw_lst.map do |penode|
            pep_ev_ref_id = penode["peptideEvidence_ref"]
            @pep_ev_h[pep_ev_ref_id]
          end 
          # get cvparams
          cvlst = psm_node.xpath('.//cvParam')
          # find spectral prob
          tmp_lst = cvlst.select{|v| v['name'] == "MS-GF:SpecEValue"}
          spec_prob = tmp_lst[0]['value']
          # get peptide
          pep_seq = @pep_h[psm_node['peptide_ref']]
          # get spectrum id/ref number
          spec_id = psm_node['id']
          spec_num = spec_id.split("_")[1].to_i
          spec_ref = spec_id.split("_")[-1].to_i
          # store in object
          psm = PSM.new(:spec_num => spec_num, 
                        :spec_ref => spec_ref, 
                        :pep => pep_seq, 
                        :spec_prob => spec_prob.to_f,
                        :mods => (@mod_h.has_key?(psm_node['peptide_ref']) ? @mod_h[psm_node['peptide_ref']] : nil),
                        :pep_ev => pep_ev_lst)
          # yield psm object
          yield psm
        end
        pbar.inc if use_pbar
      end
      pbar.finish if use_pbar
    end
    
  end

end
