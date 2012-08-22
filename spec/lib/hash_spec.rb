# encoding: UTF-8
require "spec_helper"
require "tmpdir"

describe "Hash" do
  it "should inject JSON" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    hash.data.should == {
      'name' => {'full' => 'John Bigbooté'}
    }
  end

  it "should compare hashes to file trees" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    hash.compare(repo).should == []
  end

  it "should generate repo from hash" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")

    Dir.mktmpdir() do |dir|
      hash.to_repo(dir)
      JSON.load(File.open("#{dir}/name")).should == {'full' => 'John Bigbooté'}
    end
  end

  it "should construct numbered subdirs from hash with array" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")

    Dir.mktmpdir() do |dir|
      hash.to_repo(dir)
      Dir.glob("#{dir}/emails/*").count.should == 2
      emails = Dir.glob("#{dir}/emails/*").map {|f| JSON.load(File.open(f))['email']}.to_set
      emails.should == ['johns@yoyodyne.com', "johns@lectroid.com"].to_set
      # File.read("#{dir}/emails/work/email").should == 'johns@yoyodyne.com'
    end
  end

  it "should compare array objects independently of order" do
    hash1 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    hash2 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/three.json")

    hash1.compare(hash1).should == []
    hash1.compare(hash2).should == []

    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/two")

    hash.compare(repo).should == []
  end

  it "should find differences independently of order" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/three")

    hash.compare(repo).should == [
      ["-", "emails[0]"],
      ["+", "emails[]", {"label"=>"home", "email"=>"johnsmallberries@lectroid.com"}]
    ]
    # hash.compare(repo).should == [["~", "email.home.email", "johns@lectroid.com", "johnsmallberries@lectroid.com"]]

    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/four")

    hash.compare(repo).should == [
      ["-", "emails[0]"],
      ["+", "emails[]", {"label"=>"home", "email"=>"johnsmallberries@lectroid.com"}]
    ]
    # hash.compare(repo).should == [["~", "email.home.email", "johns@lectroid.com", "johnsmallberries@lectroid.com"]]
  end
end
