require 'logger'

describe "All passed cases test" do
    before(:all) do
      puts "this line must exist before all test in All passed cases test"
    end
    it "passed test1" do
        puts "this line from passed test1"
    end

    it "passed test2" do
        puts "this line from passed test2"
    end
    
end

describe "Two failed cases test" do

    it "failed test1" do
        puts "this line from failed test1"
    end
    
    it "failed test2" do
        puts "this line from failed test2"
    end
    
    it "passed test2" do
        puts "this line from passed test2"
    end
    
end

describe "after and before" do
    after(:all) do
      puts "this line must exist after all test"
    end

    before(:all) do
      puts "this line must exist before all test"
    end

    after(:each) do
      puts "this line must exist after each test"
    end

    before(:each) do
      puts "this line must exist before each test"
    end

    it "passed test4" do
        puts "this line from passed test4"
    end

    it "passed test5" do
        puts "this line from passed test5"
    end
    
end

describe "Logger test" do

    before(:all) do
      @log = Logger.new($stdout)
      @log.level = Logger::INFO
    end

    it "passed test6" do
        puts "this line from passed test6"
    end

    it "passed test7" do
        puts "this line from passed test7"
    end
    
end

  
