# encoding: UTF-8
require "spec_helper"

describe "Hash" do
  it "should inject JSON" do
    hash = Treet::Hash.new("#{File.dirname(__FILE__)}/../json/one.json")
    hash.data.should == {
      'name' => 'John Bigbooté'
    }
  end

  # it "should compare file trees to hashes" do
  #   repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
  #   diffs = repo.compare({'name' => 'John Yaya'})
  #   diffs.should == [["~", "name", "John Bigbooté", "John Yaya"]]
  # end
end
