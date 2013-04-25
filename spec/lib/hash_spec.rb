# encoding: UTF-8
require "spec_helper"

describe Treet::Hash do
  it "should be indifferent about keys" do
    h1 = Treet::Hash.new({:name => {:full => 'John Smith'}})
    h2 = Treet::Hash.new({'name' => {'full' => 'John Smith'}})
    h1.should == h2
  end

  it "should inject JSON and do indifferent comparison" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    hash.data.should == {
      'name' => {'full' => 'John Bigbooté'}
    }
    hash.data.should == {
      :name => {:full => 'John Bigbooté'}
    }
  end

  it "should allow no empty fields" do
    hash = Treet::Hash.new({:empty => []})
    hash.data.keys.should be_empty
  end

  it "should compare hashes to file trees" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    hash.compare(repo).should == []
  end

  it "should generate repo from hash" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")

    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      JSON.load(File.open("#{dir}/name")).should == {'full' => 'John Bigbooté'}
      repo.to_hash.should == hash
      Treet::Repo.new(dir).to_hash.should == hash
    end
  end

  it "should accept symbols for keys" do
    h = {:name => {:full => 'John Bigbooté'}}
    hash = Treet::Hash.new(h)

    Dir.mktmpdir do |dir|
      hash.to_repo(dir)
      JSON.load(File.open("#{dir}/name")).should == {'full' => 'John Bigbooté'}
    end

    hash2 = Treet::Hash.new({'name' => {'full' => 'John Bigbooté'}})
    hash.eql?(hash2).should == true
  end

  it "should convert arrays to subdirs named with digests" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")

    Dir.mktmpdir do |dir|
      hash.to_repo(dir)
      Dir.glob("#{dir}/emails/*").count.should == 2
      emails = Dir.glob("#{dir}/emails/*").map {|f| JSON.load(File.open(f))['email']}.to_set
      emails.should == ['johns@yoyodyne.com', "johns@lectroid.com"].to_set
      hash.to_hash['emails'].each do |h|
        filename = "#{dir}/emails/#{Treet::Hash.digestify(h)}"
        File.should exist(filename)
      end
      # File.read("#{dir}/emails/work/email").should == 'johns@yoyodyne.com'
    end
  end

  it "should compare array objects independently of order" do
    hash1 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    hash2 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/three.json")

    hash1.compare(hash1).should == []
    hash1.compare(hash2).should == []

    hash1.should == hash1
    hash1.should == hash2

    hash1.eql?(hash1).should == true
    hash1.eql?(hash2).should == true

    hash1.hash.should == hash2.hash

    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/two")

    hash.compare(repo).should == []
  end

  it "should find differences independently of order" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/three")

    hash.compare(repo).should == [
      ["-", "emails[]", {"label"=>"home", "email"=>"johns@lectroid.com"}],
      ["+", "emails[]", {"label"=>"home", "email"=>"johnsmallberries@lectroid.com"}]
    ]
    # hash.compare(repo).should == [["~", "email.home.email", "johns@lectroid.com", "johnsmallberries@lectroid.com"]]

    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/four")

    hash.compare(repo).should == [
      ["-", "emails[]", {"label"=>"home", "email"=>"johns@lectroid.com"}],
      ["+", "emails[]", {"label"=>"home", "email"=>"johnsmallberries@lectroid.com"}]
    ]
    # hash.compare(repo).should == [["~", "email.home.email", "johns@lectroid.com", "johnsmallberries@lectroid.com"]]
  end

  it "should expand arrays of strings to empty files" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/group.json")
    Dir.mktmpdir do |dir|
      hash.to_repo(dir)
      Dir.glob("#{dir}/contacts/*").count.should == 7
    end
  end

  it "should allow comparison of string (not hash) members" do
    h1 = Treet::Hash.new({'name' => 'Bob'})
    h2 = Treet::Hash.new({'name' => 'Sally'})
    h1.compare(h2).should == [
      ['~', 'name', 'Sally', 'Bob']
    ]
  end
end

describe "shallow comparison of hashes" do
  it "should be blank for identity" do
    h1 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/bob1.json")
    h2 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/bob1.json")
    h1.compare(h2).should == []
  end

  it "should handle keys missing from one or either source hash" do
    h1 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/bob1.json")
    h2 = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/bob2.json")
    diffs = h1.compare(h2)
    diffs.sort.should == [
      ["+", "business.organization", "Acme Inc."],
      ["+", "emails[]", {"label"=>"home", "email"=>"bob@newhome.com"}],
      ["-", "emails[]", {"label"=>"home", "email"=>"bob@home.com"}],
      ["-", "emails[]", {"label"=>"other", "email"=>"bob@vacation.com"}],
      ["-", "other.notes", "some commentary"],
      ["~", "name.full", "Robert Smith", "Bob Smith"],
    ]

    h3 = h1.patch(diffs)
    h3.compare(h2).should == []
  end

  describe "comparison should ignore order of keys" do
    h1 = Treet::Hash.new(:name => "foo", :addresses => [{:bar => 'baz'}, {:bar => 'biz'}, {:bar => 'boz'}], :phones => [{:label => 'home', :phone => '123-123-1234'}], :empty => [])
    h2 = Treet::Hash.new('phones' => [{'label' => 'home', 'phone' => '123-123-1234'}], 'name' => 'foo', 'addresses' =>[{'bar' => 'boz'}, {'bar' => 'biz'}, {'bar' => 'baz'}, {'bar' => 'biz'}])
    h1.should == h2
    h1.hash.should == h2.hash
  end

  describe "arrays of strings should build lists of filenames" do
    hash = Treet::Hash.new(
        :name => 'Foo Bar',
        :entries => ["abc", "def", "ghi"]
      )
    Dir.mktmpdir do |dir|
      hash.to_repo(dir)
      Dir.glob("#{dir}/entries/*").count.should == 3
      File.exist?("#{dir}/entries/def").should == true
      File.exist?("#{dir}/entries/bogus").should == false
    end
  end
end
