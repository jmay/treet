# encoding: UTF-8
require "spec_helper"

describe "Repo" do
  it "should convert file trees to hashes" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    hash = repo.to_hash
    hash.should == {
      'name' => 'John Bigbooté'
    }
  end

  it "should compare file trees to hashes" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    diffs = repo.compare({'name' => 'John Yaya'})
    diffs.should == [["~", "name", "John Bigbooté", "John Yaya"]]
  end

  it "should flatten numbered subdirs to arrays" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/two")
    hash = repo.to_hash
    hash['email'].should == {
      'home' => {
        "email" => "johns@lectroid.com"
      },
      'work' => {
        "email" => "johns@yoyodyne.com"
      }
    }
  end

end
