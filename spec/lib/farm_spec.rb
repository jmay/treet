# encoding: UTF-8
require "spec_helper"

describe "Repository Farm" do
  it "should export as array of hashes with an xref value" do
    farm = Treet::Farm.new("#{File.dirname(__FILE__)}/../repos/farm1", :xref => 'test')
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
end
