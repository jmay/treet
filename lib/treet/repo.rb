# encoding: UTF-8

# require 'hashdiff'

class Treet::Repo
  attr_reader :root, :hash, :opts

  def initialize(path, opts = {})
    # TODO: validate that path exists and is a directory (symlinks should work)

    @root = path
    raise "Missing or invalid source path #{path}" unless File.directory?(path)
    @opts = opts
  end

  def to_hash(opts = {})
    @hash ||= expand(root, opts)
  end

  def compare(target)
    Treet::Hash.diff(to_hash, target.to_hash)
    # HashDiff.diff(to_hash, hash)
  end

  private

  def expand_json(path)
    if File.file?(path)
      begin
        JSON.load(File.open(path))
      rescue JSON::ParserError => e
        $stderr.puts "JSON syntax error in #{path}"
        nil
      end
    else
      # should be a subdirectory containing files named with numbers, each containing JSON
      files = Dir.entries(path).select {|f|  f !~ /^\./}
      files.sort_by(&:to_i).each_with_object([]) do |f, ary|
        ary << expand_json("#{path}/#{f}")
      end
    end
  end

  def expand(path, opts = {})
    files = Dir.entries(path).select {|f|  f !~ /^\./}
    hash = files.each_with_object({}) {|f,h| h[f] = expand_json("#{path}/#{f}")}

    # hash = if File.file?(path)
    #   # found a key/value hash
    #   begin
    #     JSON.load(File.open(path))
    #   rescue JSON::ParserError => e
    #     $stderr.puts "JSON syntax error in #{path}"
    #     nil
    #   end
    # else
    #   # found
    #   files = Dir.entries(path).select {|f|  f !~ /^\./}

    #   data = {}
    #   if files.all? {|f| f =~ /^\d*$/}
    #     # transform to array
    #     tree.each_with_object([]) {|f,a| a << expand("#{path}/#{f}")}.sort_by(&:hash)
    #   else
    #     # tree.each_with_object({}) {|f,h| h[f] = expand("#{path}/#{f}")}
    #   end
    # end

    if opts[:xref]
      hash['xref'] ||= {}
      hash['xref'][opts[:xref]] = @opts[:xref]
    end
    hash
  end
end
