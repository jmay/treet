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
end
