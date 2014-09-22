require 'nokogiri'

module MzID
  #
  # class to parse an mzIdentML file
  #
  class Parser
    
    def initialize(file)
      @mzid_file = file
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
        peptide_lst.each do |pnode|
          
          pseq = pnode.xpath('.//PeptideSequence')

          id = pnode['id']
          seq = pseq[0].content
          @pep_h[id] = seq
        end
        #puts "#{@pep_h.size} PEPS"            
      end
    end
    #
    # iterate through each psm
    #
    def each_psm()
      hit_values = File.open(@mzid_file) do |io|
        doc = Nokogiri::XML.parse(io, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::STRICT)
        doc.remove_namespaces!
        root = doc.root
        # get list of identifications
        spec_results = root.xpath('//SpectrumIdentificationResult')
        #puts "SPEC RESULTS:\t#{spec_results.size}"
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
            psm = PSM.new(:spec_num => spec_num, :spec_ref => spec_ref, :pep => pep_seq, :spec_prob => spec_prob.to_f)
            # yield psm object
            yield psm
          end
        end
      end
    end
    #
    # for each spectrum, return a list of PSM objects for that spectrum
    #
    def each_spectrum()
      spec_lst = []
      self.each_psm do |psm|
        if spec_lst.empty? then
          spec_lst.push(psm) 
        else
          if spec_lst[-1].get_spec_num == psm.get_spec_num then
            spec_lst.push(psm)
          else
            yield spec_lst
            spec_lst = [psm]
          end
        end
      end
      yield spec_lst
    end
    
    
    private :cache_ids
    
  end

end
