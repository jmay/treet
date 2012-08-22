# encoding: UTF-8
require "spec_helper"
require "tmpdir"

describe "Treet master" do
  it "should create a directory of UUID-labeled repos" do
    root = Treet.init("#{File.dirname(__FILE__)}/json/master.json", Dir.mktmpdir())

    Dir.glob("#{root}/*").count.should == 3
    Dir.glob("#{root}/*/emails/*").count.should == 5
    Dir.glob("#{root}/*/addresses/*").count.should == 1
  end
end
