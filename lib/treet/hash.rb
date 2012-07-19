# encoding: UTF-8

require "json"

class Treet::Hash
  attr_reader :data

  def initialize(jsonfile)
    @data = JSON.load(File.read(jsonfile))
  end
end
