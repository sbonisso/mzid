require 'nokogiri'
require 'progressbar'
require 'mzid/parser'

module MzID
  #
  # class to parse an mzIdentML file
  #
  class StreamingParser < BaseParser
    
    def initialize(file)
      @num_spec = 0
      super(file)      
    end
    #
    # given an XML.parse output from the peptide block, extract peptide sequence
    #
    def get_peptide_sequence(pnode)
      plst = pnode.xpath('.//PeptideSequence')
      id = pnode['id']
      seq = plst[0].content
    end
    #
    # given an XML.parse output from the peptide block, extract modifications
    #
    def get_modifications(pep_node)
      mods = pep_node.xpath('.//Modification')
      id = pep_node['id']
      mod_h = Hash.new
      # parse any modifications 
      mods.each do |mod|
        loc = mod['location'].to_i-1
        delta_mass = mod['monoisotopicMassDelta'].to_f
        if !mod_h.empty? then 
          mod_h.merge!( loc => delta_mass )
        else
          mod_h = {mod['location'].to_i-1 => delta_mass}
        end
      end
      mod_h.empty? ? nil : mod_h
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
                        :mods => (@mod_h.has_key?(psm_node['peptide_ref']) ? @mod_h[psm_node['peptide_ref']] : nil))
          # yield psm object
          yield psm
        end
        pbar.inc if use_pbar
      end
      pbar.finish if use_pbar
    end

    private :get_peptide_sequence, :get_modifications
  end

end
