# encoding: UTF-8
require "spec_helper"

describe "Repo" do
  it "should convert file trees to hashes" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    repo.to_hash.should == {
      'name' => {'full' => 'John Bigbooté'}
    }
  end

  it "should generate optional " do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    repo.to_hash.should == {
      'name' => {'full' => 'John Bigbooté'}
    }
  end

  it "should compare file trees to hashes" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    repo.compare({'name' => {'full' => 'John Yaya'}}).should == [
      ["~", "name.full", "John Yaya", "John Bigbooté"]
    ]
  end

  it "should flatten numbered subdirs to arrays" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/two")
    hash = repo.to_hash
    hash['emails'].to_set.should == [
      {
        "label" => "home",
        "email" => "johns@lectroid.com"
      },
      {
        "label" => "work",
        "email" => "johns@yoyodyne.com"
      }
    ].to_set
  end

  it "should generate file paths correctly from key paths in patches" do
    Treet::Repo.filefor("name.first").should == [".", "name", "first"]
    Treet::Repo.filefor("emails[]").should == ['emails', "", nil]
  end

  it "should added xref keys when specified" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one", :xrefkey => 'foo', :xref => 'bar')
    repo.to_hash.should == {
      'name' => {'full' => 'John Bigbooté'},
      'xref' => {'foo' => 'bar'}
    }
  end

  it "should take patches that add values to missing elements" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      repo.patch([
        [
          "~",
          "name.full",
          "John von Neumann"
        ],
        [
          "+",
          "foo.bar",
          "new value"
        ]
      ])
      newhash = repo.to_hash
      newhash['name']['full'].should == 'John von Neumann'
      newhash['foo']['bar'].should == 'new value'
    end
  end

  it "should accept patches that edit inside missing subhashes" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      repo.patch([
        [
          "~",
          "foo.bar",
          "new value"
        ]
      ])
      newhash = repo.to_hash
      newhash['foo']['bar'].should == 'new value'
    end
  end
end
