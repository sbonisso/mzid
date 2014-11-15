mzid
====

ruby parser library for mzIdentML files

[![Build Status](https://travis-ci.org/sbonisso/mzid.png)](http://travis-ci.org/sbonisso/mzid)

###### Install

``` ruby
gem build ./mzid.gemspec
```

```ruby
gem install mzid
```

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
