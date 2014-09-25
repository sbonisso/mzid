require 'nokogiri'
require 'progressbar'
require 'mzid/base_parser'

module MzID
  #
  # class to parse an mzIdentML file
  #
  class BatchParser < BaseParser
    
    def initialize(file)
      super(file)
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
        peptide_lst = root.xpath('//Peptide')
        @pep_h = Hash.new
        @mod_h = Hash.new
        peptide_lst.each do |pnode|
          
          pep_id = pnode['id']
          pep_seq = get_peptide_sequence(pnode)
          mod_line = get_modifications(pnode)
          @pep_h[pep_id] = pep_seq 
          @mod_h[pep_id] = mod_line 
          
          # pseq = pnode.xpath('.//PeptideSequence')
          # mods = pnode.xpath('.//Modification')
          # # parse the peptide sequence
          # id = pnode['id']
          # seq = pseq[0].content
          # @pep_h[id] = seq
          # # parse any modifications 
          # mods.each do |mod|
          #   loc = mod['location'].to_i-1
          #   delta_mass = mod['monoisotopicMassDelta'].to_f
          #   if @mod_h.has_key?(id) then 
          #     @mod_h[id].merge!( loc => delta_mass )
          #   else
          #     @mod_h[id] = {mod['location'].to_i-1 => delta_mass}
          #   end
          # end
          
        end
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
            #puts psm_node.to_s
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
