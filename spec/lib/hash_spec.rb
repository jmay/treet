# encoding: UTF-8
require "spec_helper"
require "tmpdir"

describe "Hash" do
  it "should inject JSON" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    hash.data.should == {
      'name' => 'John Bigbooté'
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
      File.read("#{dir}/name").should == 'John Bigbooté'
    end
  end

  it "should construct numbered subdirs from hash with array" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")

    Dir.mktmpdir() do |dir|
      hash.to_repo(dir)
      File.read("#{dir}/email/1/label").should == 'work'
    end
  end

  it "should compare array objects independently of order" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/two.json")
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/two")

    hash.compare(repo).should == []
  end
end
