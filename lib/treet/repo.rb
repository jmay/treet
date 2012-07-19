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
# def create(data, filename)
#   case data
#   when Hash
#     unless filename == '.'
#       Dir.mkdir(filename) rescue nil
#     end
#     Dir.chdir(filename) do
#       data.each do |name,body|
#         create(body,name)
#       end
#     end
#   else
#     File.open(filename, "w") {|f| f << data}
#   end
# end
