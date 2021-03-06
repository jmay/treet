# encoding: UTF-8

class Treet::Repo
  attr_reader :root

  def initialize(path, opts = {})
    raise Errno::ENOENT, "Missing or invalid source path #{path}" unless File.directory?(path)

    @root = path
  end

  def to_hash
    expand(root)
  end

  def compare(target)
    Treet::Hash.diff(to_hash, target.to_hash)
  end

  # patch keys can look like
  #   name.first
  #   emails[]
  # (address[1] syntax has been eliminated, we recognize array elements by matching the entire content)
  def self.filefor(keyname)
    if keyname =~ /\[/
      keyname = keyname.match(/^(.*)\[\]$/).captures.first
      [keyname, '', nil]
    elsif keyname =~ /\./
      # subelement
      # negative lookbehind; don't split on a dot at beginning of string
      filename,field = keyname.split(/(?<!^)\./)
      ['.', filename, field]
    else
      ['.', keyname]
    end
  end

  # Patching a repo is not the same as patching a hash. Make the changes
  # directly to the data files.
  def patch(diffs)
    @hash = nil # invalidate any cached image

    Dir.chdir(root) do
      diffs.each do |diff|
        flag, key, v1, _ = diff
        # if key =~ /\[/
        #   keyname = key.match(/^(.*)\[\]$/).captures
        # elsif key =~ /\./
        #   keyname, subkey = key.match(/^(.*)\.(.*)$/).captures
        # else
        #   keyname = key
        # end

        dirname, filename, fieldname = Treet::Repo.filefor(key)
        filepath = "#{dirname}/#{filename}"

        case flag
        when '~'
          # change a value in place
          # load the current data & overwrite with the new value
          # idempotent: this will overwrite the file with the same contents
          if fieldname
            # hash entry
            data = File.exists?(filepath) ? JSON.load(File.open(filepath)) : {}
            data[fieldname] = v1
            File.open(filepath, "w") {|f| f << JSON.pretty_generate(data)}
          else
            # string entry
            File.open(filepath, "w") {|f| f << v1}
          end

        when '+'
          # add something
          if fieldname
            # writing a value into a hash
            # idempotent: this will overwrite the file with the same contents
            data = File.exists?(filepath) ? JSON.load(File.open(filepath)) : {}
            data[fieldname] = v1
            Dir.mkdir(dirname) unless Dir.exists?(dirname)
            File.open(filepath, "w") {|f| f << JSON.pretty_generate(data)}
          else
            # writing an entire hash into an array entry
            # idempotent: this will overwrite the file with the same contents
            subfile = "#{dirname}/#{Treet::Hash.digestify(v1)}"
            Dir.mkdir(dirname) unless Dir.exists?(dirname)
            case v1
            when Hash
              # hash entry
              File.open(subfile, "w") {|f| f << JSON.pretty_generate(v1)}
            else
              # string entry - create empty file with this name
              FileUtils.touch(subfile)
            end
          end

        when '-'
          # remove something
          if fieldname
            # this is a key in a subhash
            if File.exists?(filepath)
              # if the subhash is missing, there's nothing to remove, so do nothing (for idempotence)
              data = JSON.load(File.open(filepath))
              data.delete(fieldname)
              if data.empty?
                # all keys have been removed, clean up the file
                File.delete(filename)
              else
                File.open(filepath, "w") {|f| f << JSON.pretty_generate(data)}
              end
            end
          elsif dirname == "."
            # this is a top-level string
            File.delete(filename) if File.exists?(filename) # need the existence check for idempotence
          else
            # this is an array, we look for a match on the entire contents via digest
            subfile = "#{dirname}/#{Treet::Hash.digestify(v1)}"
            File.delete(subfile) if File.exists?(subfile) # need the existence check for idempotence
            # TODO: if dirname is now empty, should it be removed? is that worthwhile?
          end
        end
      end
    end

    to_hash # ?? return the patched data? or no return value? true/false for success?
  end

  private

  def expand_json(path)
    if File.file?(path)
      if File.zero?(path)
        # empty files are just keys or string elements in an array
        File.basename(path)
      else
        # if file contents is JSON, then parse it
        # otherwise treat it as a raw string value
        s = File.read(path)
        JSON.load(s) rescue s
      end
    else
      # should be a subdirectory containing files named with numbers, each containing JSON
      files = Dir.entries(path).select {|f|  f !~ /^\./}
      files.sort_by(&:to_i).each_with_object([]) do |f, ary|
        ary << expand_json("#{path}/#{f}")
      end
    end
  end

  def expand(path)
    raw = filenames(path).each_with_object({}) {|f,h| h[f] = expand_json("#{path}/#{f}")}
    Treet::Hash.new(raw)
  end

  def filenames(path)
    Dir.entries(path).select {|f|  f !~ /^\./}
  end
end
