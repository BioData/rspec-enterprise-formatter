rspec-html-formator
===================

Extended html formator for rspec. It create seperate html file for each rspec test script.
It is useful when you have large number of rspec testcases with different owners.

### how to use
rspec -r ./lib/splithtml_formatter.rb ./lib/splithtml_printer.rb -f SplithtmlFormatter spec/sample_spec.rb

### Dependence
ruby 1.8.7

