# encoding: UTF-8
require "spec_helper"

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
    farm = Treet::Farm.plant(:json => "#{File.dirname(__FILE__)}/../json/master.json", :root => Dir.mktmpdir)

    Dir.glob("#{farm.root}/*").count.should == 3
    Dir.glob("#{farm.root}/*/emails/*").count.should == 5
    Dir.glob("#{farm.root}/*/addresses/*").count.should == 1

    FileUtils.rm_rf(farm.root)
  end

  it "should be retrievable by repo label/xref" do
    farm = Treet::Farm.new(:root => "#{File.dirname(__FILE__)}/../repos/farm1", :xref => 'test')
    farm['two'].root.should == "#{File.dirname(__FILE__)}/../repos/farm1/two"
    farm['two'].to_hash['xref'].should == {'test' => 'two'}
  end

  it "should take additions" do
    farm = Treet::Farm.plant(:json => "#{File.dirname(__FILE__)}/../json/master.json", :root => Dir.mktmpdir)

    bob_hash = load_json("bob1")
    repo = farm.add(bob_hash)
    repo.root.should =~ /#{farm.root}/
    Dir.glob("#{farm.root}/*").count.should == 4

    FileUtils.rm_rf(farm.root)
  end
end
