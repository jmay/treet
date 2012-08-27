# encoding: UTF-8
require "spec_helper"

describe "Repo" do
  it "should convert file trees to hashes" do
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
end
