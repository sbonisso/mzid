mzid
====

ruby parser library for mzIdentML files

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

###### Dependencies
* nokogiri
* progressbar
* minitest
* minitest-reporters
