# encoding: UTF-8
require "spec_helper"

describe "Repo" do
  it "should be able to ignore rows with blank fields" do
    repo = Treet::Repo.new("#{File.dirname(__FILE__)}/../repos/one")
    hash = repo.to_hash
    hash.should == {
      'name' => 'John Bigbooté'
    }
  end
end
