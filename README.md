rspec-html-formator
===================

Extended html formator for rspec. It create seperate html file for each rspec test script.
It is useful when you have large number of rspec testcases with different owners.

### install
`gem install rspec-html-formatter`

### how to use
```
export HTML_REPORTS=/tmp/reports
rspec -f SplithtmlFormatter -r splithtml_formatter -r splithtml_printer spec/sample_spec.rb 
```
The log files will be created into $HTML_REPORTS  
If it is not set, use "`pwd`/spec/reports"

### dependence
rspec 3 since version 0.0.1

for rspec 2.14, `gem install rspec-html-formatter -v 0.0.0`
