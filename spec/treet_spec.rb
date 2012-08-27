# encoding: UTF-8
require "spec_helper"
require "tmpdir"

describe "Treet master" do
  it "should create a directory of UUID-labeled repos" do
    farm = Treet.init(:json => "#{File.dirname(__FILE__)}/json/master.json", :root => Dir.mktmpdir())

    Dir.glob("#{farm.root}/*").count.should == 3
    Dir.glob("#{farm.root}/*/emails/*").count.should == 5
    Dir.glob("#{farm.root}/*/addresses/*").count.should == 1
  end
end
