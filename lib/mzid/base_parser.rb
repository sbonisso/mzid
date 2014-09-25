require 'nokogiri'
require 'progressbar'

module MzID
  #
  # class to parse an mzIdentML file
  #
  class BaseParser
    
    def initialize(file)
      @mzid_file = file
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
    
    private :get_peptide_sequence, :get_modifications

  end
  
end
