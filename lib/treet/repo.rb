# encoding: UTF-8

class Treet::Repo
  attr_reader :root

  def initialize(path)
    # TODO: validate that path exists and is a directory (symlinks should work)

    @root = path
  end

  def to_hash
    expand(root)
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
