# encoding: UTF-8

require "json"
require "digest/sha1"

class Treet::Hash
  attr_reader :data

  # when loading an Array (at the top level), members are always sorted
  # so that array comparisons will be order-independent
  def initialize(source)
    d = case source
    when Hash
      source
    when String
      # treat as filename
      JSON.load(File.read(source))
    else
      raise "Invalid source data type #{source.class} for Treet::Hash"
    end

    @data = normalize(d)
  end

  def to_repo(root, opts = {})
    construct(data, root)
    repotype = opts[:repotype] || Treet::Repo
    repotype.new(root, opts)
  end

  def to_hash
    data.to_hash
  end

  def compare(target)
    # HashDiff.diff(data, target.to_hash)
    Treet::Hash.diff(data.to_hash, target.to_hash)
  end

  # apply diffs (created via the `#compare` function) to create a new object
  def patch(diffs)
    newhash = Treet::Hash.patch(self.to_hash, diffs)
    Treet::Hash.new(newhash)
  end

  def self.digestify(data)
    case data
    when Hash
      Digest::SHA1.hexdigest(data.to_a.sort.flatten.join)
    else # String
      data
    end
  end

  private

  def construct(data, filename)
    unless filename == '.'
      # create the root of the repository tree
      Dir.mkdir(filename) rescue nil
    end

    Dir.chdir(filename) do
      data.each do |k,v|
        case v
        when Hash
          File.open(k.to_s, "w") {|f| f << JSON.pretty_generate(v)}

        when Array
          Dir.mkdir(k.to_s)
          v.each do |v2|
            case v2
            when String
              # create empty file with this name
              FileUtils.touch("#{k}/#{v2}")

            else
              # store object contents as JSON into a generated filename
              subfile = "#{k}/#{Treet::Hash.digestify(v2)}"
              File.open(subfile, "w") {|f| f << JSON.pretty_generate(v2)}
            end
          end

        when String
          File.open(k.to_s, "w") {|f| f << v}

        else
          raise "Unsupported object type #{v.class} for '#{k}'"
        end
      end
    end
  end

  def normalize(hash)
    hash.each_with_object({}) do |(k,v),h|
      case v
      when Array
        if v.map(&:class).uniq == Hash
          # all elements are Hashes
          h[k] = v.sort do |a,b|
            a.to_a.sort_by(&:first).flatten <=> b.to_a.sort_by(&:first).flatten
          end
        else
          h[k] =v
        end

      else
        h[k] = v
      end
    end
  end

  # Diffs need to be idempotent when applied via patch.
  # Therefore we can't specify individual index positions for an array, because items can move.
  # Instead, we must include the entire contents of the sub-hash, and during the patch process
  # compare that against each element in the array.
  # This means that an array cannot have exact duplicate entries.
  def self.diff(hash1, hash2)
    diffs = []

    keys = hash1.keys | hash2.keys
    keys.each do |k|
      # if a value is missing from hash1, create a dummy of the same type that appears in hash2
      v1 = hash1[k] || hash2[k].class.new
      v2 = hash2[k] || hash1[k].class.new

      case v1
      when Hash
        (v2.keys - v1.keys).each do |k2|
          # new sub-elements: (-, key, after-value)
          diffs << ['+', "#{k}.#{k2}", v2[k2]]
        end
        (v1.keys - v2.keys).each do |k2|
          # deleted sub-elements: (-, key, before-value)
          diffs << ['-', "#{k}.#{k2}", v1[k2]]
        end
        (v1.keys & v2.keys).each do |k2|
          if v1[k2] != v2[k2]
            # altered sub-elements: (~, key, after-value, before-value-for-reference)
            diffs << ['~', "#{k}.#{k2}", v2[k2], v1[k2]]
          end
        end

      when Array
        v1.each do |e1|
          if !v2.include?(e1)
            # element has been removed
            diffs << ['-', "#{k}[]", e1]
          end
        end

        (v2 - v1).each do |e2|
          # new array element
          diffs << ['+', "#{k}[]", e2]
        end

      else # scalar values
        if v1 != v2
          if v1.nil?
            diffs << ['+', k, v2]
          elsif v2.nil?
            diffs << ['-', k, v1]
          else
            diffs << ['~', k, v2, v1]
          end
        end

      end
    end

    diffs
  end

  def self.patch(hash, diffs)
    result = hash.dup

    diffs.each do |diff|
      flag, key, v1, v2 = diff
      if key =~ /\[/
        keyname, is_array = key.match(/^(.*)(\[\])$/).captures
      elsif key =~ /\./
        keyname, subkey = key.match(/^(.*)\.(.*)$/).captures
      else
        keyname = key
      end

      case flag
      when '~'
        # change a value in place

        if subkey
          result[keyname][subkey] = v1
        else
          result[keyname] = v1
        end

      when '+'
        # add something
        if subkey
          result[keyname] ||= {}
          result[keyname][subkey] = v1
        elsif is_array
          result[keyname] ||= []
          result[keyname] << v1
        else
          result[keyname] = v1
        end

      when '-'
        # remove something
        if subkey
          result[keyname].delete(subkey)
        elsif is_array
          result[keyname].delete_if {|v| v == v1}
        else
          result.delete(keyname)
        end
      end
    end

    result.delete_if {|k,v| v.nil? || v.empty?}

    result
  end
end
