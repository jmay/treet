# encoding: UTF-8
require "test_helper"

describe "Repository Farm" do
  it "should export as array of hashes with an xref value" do
    farm = Treet::Farm.new(:root => "#{File.dirname(__FILE__)}/../repos/farm1", :xref => 'test')
    farm.repos.count.must_equal 2
    farm.export.must_equal [
      {
        'name' => {
          'full' => 'John Bigbooté'
        }
      },
      {
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

    Dir.glob("#{farm.root}/*").count.must_equal 3
    Dir.glob("#{farm.root}/*/emails/*").count.must_equal 5
    Dir.glob("#{farm.root}/*/addresses/*").count.must_equal 1

    FileUtils.rm_rf(farm.root)
  end

  # it "should be retrievable by repo label/xref" do
  #   farm = Treet::Farm.new(:root => "#{File.dirname(__FILE__)}/../repos/farm1", :xref => 'test')
  #   farm['two'].root.must_equal "#{File.dirname(__FILE__)}/../repos/farm1/two"
  #   farm['two'].to_hash['xref'].must_equal {'test' => 'two'}
  # end

  it "should take additions" do
    farm = Treet::Farm.plant(:json => "#{File.dirname(__FILE__)}/../json/master.json", :root => Dir.mktmpdir)
    farm.repos.count.must_equal 3

    bob_hash = load_json("bob1")
    repo = farm.add(bob_hash)
    repo.root.must_match /#{farm.root}/
    Dir.glob("#{farm.root}/*").count.must_equal 4

    farm.repos.count.must_equal 4

    # now try with a predefined ID
    repo = farm.add(bob_hash, :id => '12345')
    repo.root.must_equal "#{farm.root}/12345"
    Dir.glob("#{farm.root}/*").count.must_equal 5

    FileUtils.rm_rf(farm.root)
  end
end
