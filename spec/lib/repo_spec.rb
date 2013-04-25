# encoding: UTF-8
require "spec_helper"

describe "Repo" do
  it "should convert file trees to hashes" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    repo.to_hash.should == {
      'name' => {'full' => 'John Bigbooté'}
    }
    repo.to_hash.should == {
      :name => {:full => 'John Bigbooté'}
    }
  end

  it "should reload on reset" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    repo.to_hash.should == {
      'name' => {'full' => 'John Bigbooté'}
    }
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
    Treet::Repo.filefor("topvalue").should == ['.', "topvalue"]
  end

  # it "should add xref keys when specified" do
  #   repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one", :xrefkey => 'foo', :xref => 'bar')
  #   repo.to_hash.should == {
  #     'name' => {'full' => 'John Bigbooté'},
  #     'xref' => {'foo' => 'bar'}
  #   }
  # end

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

  it "should accept patches that update top-level values" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/four.json")
    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      repo.patch([
        [
          "~",
          "title",
          "Updated Title"
        ]
      ])
      newhash = repo.to_hash
      newhash['title'].should == 'Updated Title'

      repo.patch([
        [
          "-",
          "datalist[]",
          "two"
        ]
      ])
      newhash = repo.to_hash
      newhash['datalist'].count.should == 2
    end
  end

  it "should add hash entries inside existing arrays" do
    hash = Treet::Hash.new(load_json('two'))
    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      repo.patch([
        [
          "+",
          "emails[]",
          {"label" => "home", "label" => "myname@gmail.com"}
        ]
      ])
      newhash = repo.to_hash
      newhash['emails'].count.should == 3
      newhash['emails'].each {|x| x.is_a?(Hash).should be_true}
    end
  end

  it "should clean up after a subhash deletion patch" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      repo.patch([
        [
          "-",
          "name.full",
          "oldval"
        ]
      ])
      newhash = repo.to_hash
      newhash.keys.should be_empty
    end
  end

  it "should clean up after a top-level string deletion patch" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/four.json")
    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      repo.patch([
        [
          "-",
          "title",
          "oldval"
        ]
      ])
      newhash = repo.to_hash
      newhash.keys.should == ['datalist']
    end
  end

  it "should create empty files correctly when patch adds elements" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/four.json")
    Dir.mktmpdir do |dir|
      repo = hash.to_repo(dir)
      repo.patch([
        [
          "+",
          "datalist[]",
          "two"
        ],
        [
          "+",
          "datalist[]",
          "seven"
        ]
      ])
      newhash = repo.to_hash
      newhash.to_hash['datalist'].should be_include('seven')
    end
  end
end
