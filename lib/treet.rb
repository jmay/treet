require "treet/version"

require_relative "treet/repo"
require_relative "treet/hash"

require "uuidtools"

module Treet
  def self.init(jsonfile, dir)
    array_of_hashes = JSON.load(File.open(jsonfile))
    Dir.chdir(dir) do
      array_of_hashes.each do |h|
        uuid = UUIDTools::UUID.random_create.to_s
        thash = Treet::Hash.new(h)
        repo = thash.to_repo(uuid)
      end
    end
    dir
  end
end
