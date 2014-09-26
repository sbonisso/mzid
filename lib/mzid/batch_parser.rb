require 'nokogiri'
require 'progressbar'
require 'mzid/base_parser'
require 'mzid/peptide_evidence'

module MzID
  #
  # class to parse an mzIdentML file
  #
  class BatchParser < BaseParser
    
    def initialize(file)
      super(file)
      @pep_ev_h = Hash.new
      @db_seq_h = Hash.new
      cache_ids
    end
    #
    # store peptide sequences in hash for lookup
    #
    def cache_ids()
      hit_values = File.open(@mzid_file) do |io|
        doc = Nokogiri::XML.parse(io, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::STRICT)
        doc.remove_namespaces!
        root = doc.root
        
        cache_db_seq_entries(root)
        cache_pep_ev(root)
        
        peptide_lst = root.xpath('//Peptide')
        @pep_h = Hash.new
        @mod_h = Hash.new
        peptide_lst.each do |pnode|
          
          pep_id = pnode['id']
          pep_seq = get_peptide_sequence(pnode)
          mod_line = get_modifications(pnode)
          @pep_h[pep_id] = pep_seq 
          @mod_h[pep_id] = mod_line 
        end
        
      end
    end
    #
    # store peptide evidence sequences in hash for lookup
    #
    def cache_pep_ev(root)
      pep_ev_lst = root.xpath('//PeptideEvidence')
      pep_ev_lst.each do |pnode|
        id = pnode["id"]
        
        @pep_ev_h[id] = 
          PeptideEvidence.new(:id => pnode["id"],
                              :db_seq_ref => pnode["dBSequence_ref"],
                              :pep_id => pnode["peptide_ref"],
                              :start_pos => pnode["start"],
                              :end_pos => pnode["end"],
                              :pre => pnode["pre"],
                              :post => pnode["post"],
                              :prot_id => @db_seq_h[pnode["dBSequence_ref"]])
      end
    end
    #
    # store database sequence entries (ids) 
    #
    def cache_db_seq_entries(root)
      dbseq_lst = root.xpath('//DBSequence')
      dbseq_lst.each do |dnode|
        id = dnode["id"]
        acc_id = dnode["accession"]
        @db_seq_h[id] = acc_id
      end
    end 
    #
    # iterate through each psm
    #
    def each_psm(use_pbar=nil)
      hit_values = File.open(@mzid_file) do |io|
        doc = Nokogiri::XML.parse(io, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::STRICT)
        doc.remove_namespaces!
        root = doc.root
        # get list of identifications
        spec_results = root.xpath('//SpectrumIdentificationResult')
        pbar = ProgressBar.new("PSMs", spec_results.size) if use_pbar
        spec_results.each do |sres|
          # 
          psms_of_spec = sres.xpath('.//SpectrumIdentificationItem')
          # go over each PSM from the spectra
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
                          :pep_ev => pep_ev_lst
                          )
            # yield psm object
            yield psm
          end
          pbar.inc if use_pbar
        end
        pbar.finish if use_pbar
      end
    end
    #
    # for each spectrum, return a list of PSM objects for that spectrum
    #
    def each_spectrum(use_pbar=nil)
      spec_lst = []
      self.each_psm(use_pbar) do |psm|
        if spec_lst.empty? then
          spec_lst.push(psm) 
        else
          if spec_lst[-1].get_spec_num == psm.get_spec_num then
            spec_lst.push(psm)
          else # found new spec num, yield psm list
            yield spec_lst
            spec_lst = [psm] # add new to list
          end
        end
      end
      yield spec_lst
    end
    
    
    private :cache_ids
    
  end

end
