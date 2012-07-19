# encoding: UTF-8

require 'hashdiff'

class Treet::Repo
  attr_reader :root, :hash

  def initialize(path)
    # TODO: validate that path exists and is a directory (symlinks should work)

    @root = path
  end

  def to_hash
    @hash ||= expand(root)
  end

  def compare(hash)
    HashDiff.diff(to_hash, hash)
  end

  private

  def expand(path)
    if File.file?(path)
      return File.read(path)
    end

    tree = Dir.entries(path).select {|f|  f !~ /^\./}
    tree.each_with_object({}) {|f,h| h[f] = expand("#{path}/#{f}")}
  end
end
