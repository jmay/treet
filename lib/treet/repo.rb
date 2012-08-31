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

  # patch keys can look like
  #   name.first
  #   addresses[0]
  #   emails[]
  def self.filefor(keyname)
    if keyname =~ /\[/
      keyname, is_array, index = keyname.match(/^(.*)(\[)(.*)\]$/).captures
      [keyname, index, nil]
    elsif keyname =~ /\./
      # subelement
      filename,field = keyname.split('.')
      ['.', filename, field]
    else
      [nil, keyname]
    end
  end

  # Patching a repo is not the same as patching a hash. Make the changes
  # directly to the data files. Invalidate any cached hash image so it
  # will be reloaded.
  def patch(diffs)
    @hash = nil

    Dir.chdir(root) do
      diffs.each do |diff|
        flag, key, v1, v2 = diff
        if key =~ /\[/
          keyname, is_array, index = key.match(/^(.*)(\[)(.*)\]$/).captures
        elsif key =~ /\./
          keyname, subkey = key.match(/^(.*)\.(.*)$/).captures
        else
          keyname = key
        end

        dirname, filename, fieldname = Treet::Repo.filefor(key)
        case flag
        when '~'
          # change a value in place
          # assumes that filename already exists
          puts "UPDATE #{v1} to #{filename}:#{fieldname}"
          # data = JSON.load(File.open("#{dirname}/#{filename}"))
          # data[fieldname] = v1
          # File.open("#{dirname}/#{filename}", "w") {|f| f << JSON.pretty_generate(data)}

        when '+'
          # add something
          if fieldname
            puts "WRITE #{v1.inspect} to #{filename}:#{fieldname}"
            # data = JSON.load(File.open("#{dirname}/#{filename}"))
            # data[fieldname] = v1
            # File.open("#{dirname}/#{filename}", "w") {|f| f << JSON.pretty_generate(data)}
          else
            subfile = "#{dirname}/#{Treet::Hash.digestify(v1)}"
            puts "SAVE #{v1.inspect} to #{subfile}"
            # Dir.mkdir(dirname) unless Dir.exists?(dirname)
            # File.open("#{dirname}/#{filename}", "w") {|f| f << JSON.pretty_generate(v1)}
          end

        when '-'
          # remove something
          if fieldname
            puts "DELETE #{filename}:#{fieldname}"
            # data = JSON.load(File.open("#{dirname}/#{filename}"))
            # data.delete(fieldname)
            # if data.empty?
            #   File.delete(filename)
            # else
            #   File.open("#{dirname}/#{filename}", "w") {|f| f << JSON.pretty_generate(data)}
            # end
          else
            subfile = "#{dirname}/#{Treet::Hash.digestify(v1)}"
            puts "DELETE #{subfile} FORMERLY #{v1}"
            # Dir.mkdir(dirname) unless Dir.exists?(dirname)
            # File.open("#{dirname}/#{filename}", "w") {|f| f << JSON.pretty_generate(v1)}
            # TODO: delete {dirname} if empty? is it worth the trouble to clean up these dirs?
          end
        end
      end
    end

    to_hash # ?? return the patched data? or no return value? true/false for success?
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

    if opts[:xref]
      hash['xref'] ||= {}
      hash['xref'][opts[:xref]] = @opts[:xref]
    end
    hash
  end
end
