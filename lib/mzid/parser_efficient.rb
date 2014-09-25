require 'nokogiri'
require 'progressbar'
require 'mzid/parser'

module MzID
  #
  # class to parse an mzIdentML file
  #
  class ParserEfficient < Parser
    
    def initialize(file)
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
        if mod_h.has_key?(id) then 
          mod_h[id].merge!( loc => delta_mass )
        else
          mod_h[id] = {mod['location'].to_i-1 => delta_mass}
        end
      end
      mod_h
    end
    #
    # store peptide sequences in hash for lookup
    #
    def cache_ids()
      @pep_h = Hash.new
      @mod_h = Hash.new
      reader = Nokogiri::XML::Reader(File.open(@mzid_file))
      reader.each do |node|
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
      puts "#{@pep_h.size} peptides"
    end

    private :get_peptide_sequence, :get_modifications
  end

end
