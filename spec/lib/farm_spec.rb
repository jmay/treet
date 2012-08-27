# encoding: UTF-8
require "spec_helper"

require "tmpdir"

describe "Repository Farm" do
  it "should export as array of hashes with an xref value" do
    farm = Treet::Farm.new(:root => "#{File.dirname(__FILE__)}/../repos/farm1", :xref => 'test')
    farm.export.should == [
      {
        'name' => {
          'full' => 'John Bigbooté'
        },
        'xref' => {
          'test' => 'one'
        }
      },
      {
        'xref' => {
          'test' => 'two'
        },
        'name' => {
          'full' => 'John Smallberries',
          'first' => 'John',
          'last' => 'Smallberries'
        },
        'emails' => [
          {
            "label" => "home",
            "email" => "johns@lectroid.com"
          },
          {
            "label" => "work",
            "email" => "johns@yoyodyne.com"
          }
        ]
      }
    ]
  end

  it "planting should create a directory of UUID-labeled repos" do
    farm = Treet::Farm.plant(:json => "#{File.dirname(__FILE__)}/../json/master.json", :root => Dir.mktmpdir())

    Dir.glob("#{farm.root}/*").count.should == 3
    Dir.glob("#{farm.root}/*/emails/*").count.should == 5
    Dir.glob("#{farm.root}/*/addresses/*").count.should == 1
  end
end
