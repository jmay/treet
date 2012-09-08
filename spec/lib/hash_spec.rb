# encoding: UTF-8
require "spec_helper"

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

    Dir.mktmpdir do |dir|
      hash.to_repo(dir)
      JSON.load(File.open("#{dir}/name")).should == {'full' => 'John Bigbooté'}
    end
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
        File.exist?(filename).should be_true
      end
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
    # diffs.should include(["~", "name.full", "Bob Smith", "Robert Smith"])
    # diffs.should include(["+", "business.organization", "Acme Inc."])
    # diffs.should include(["-", "other.notes", "some commentary"])
    diffs.should == [
      ["~", "name.full", "Robert Smith", "Bob Smith"],
      ["-", "emails[]", {"label"=>"home", "email"=>"bob@home.com"}],
      ["-", "emails[]", {"label"=>"other", "email"=>"bob@vacation.com"}],
      ["+", "emails[]", {"label"=>"home", "email"=>"bob@newhome.com"}],
      ["-", "other.notes", "some commentary"],
      ["+", "business.organization", "Acme Inc."]
    ]

    h3 = h1.patch(diffs)
    h3.compare(h2).should == []
  end

end
