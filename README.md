mzid
====

ruby parser library for mzIdentML files

[![Gem Version](https://badge.fury.io/rb/mzid.svg)](http://badge.fury.io/rb/mzid)
[![Build Status](https://travis-ci.org/sbonisso/mzid.png)](http://travis-ci.org/sbonisso/mzid)

###### Install

``` ruby
gem build ./mzid.gemspec
```

```ruby
gem install mzid
```

###### Usage

A command line utility is provided to convert from mzid to csv, an example:

```
$ convert_mzid_to_csv.rb test.mzid -v -m 
DBSeq:         100% |oooooooooooooooooooooooooooooooooooooooooooooooooooooooooo| Time:   0:00:01
Peptides:      100% |oooooooooooooooooooooooooooooooooooooooooooooooooooooooooo| Time:   0:00:01
PepEv:         100% |oooooooooooooooooooooooooooooooooooooooooooooooooooooooooo| Time:   0:00:01
Spectra:       100% |oooooooooooooooooooooooooooooooooooooooooooooooooooooooooo| Time:   0:00:02
```

this results in a file named test.csv since one was not explicitly provided.

###### Example

parsing the output of an mzid file can be done in a simple block:

```ruby
require 'mzid'

parser = MzID::Parser.new("output.mzid")
parser.each_psm do |spec_id|
  puts [spec_id.get_id, spec_id.get_pep, spec_id.get_spec_prob].join("\t")
end
```

alternatively, one can also specify a more memory-efficient parser for large files, 
reformatting their output into an easily parsable csv file:

```ruby
parser = MzID::ParserSax.new("output.mzid")
parser.write_to_csv("output.csv")
```

###### Dependencies
* nokogiri
* ox
* progressbar
* minitest
* minitest-reporters
