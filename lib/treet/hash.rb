# encoding: UTF-8

require "json"

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

  def to_repo(root)
    construct(data, root)
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
          File.open(k, "w") {|f| f << v.to_json}

        when Array
          Dir.mkdir(k)
          v.each_with_index do |v2, i|
            case v2
            when String
              # create empty file with this name
              File.open("#{k}/#{v2}", "w")

            else
              # store object contents as JSON into a generated filename
              File.open("#{k}/#{i}", "w") {|f| f << v2.to_json}
            end
          end

        when String
          File.open(k, "w") {|f| f << v}

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
          # new sub-elements
          diffs << ['+', "#{k}.#{k2}", v2[k2]]
        end
        (v1.keys - v2.keys).each do |k2|
          # deleted sub-elements
          diffs << ['-', "#{k}.#{k2}", v1[k2]]
        end
        (v1.keys & v2.keys).each do |k2|
          if v1[k2] != v2[k2]
            # altered sub-elements
            diffs << ['~', "#{k}.#{k2}", v1[k2], v2[k2]]
          end
        end

      when Array
        # assume that arrays have been sorted per `normalize`
        a1 = v1
        a2 = v2

        a1.each_with_index do |v1, i|
          if !a2.include?(v1)
            # element has been removed
            diffs << ['-', "#{k}[#{i}]", v1]
          end
        end

        (a2 - a1).each do |v2|
          # new array element
          diffs << ['+', "#{k}[]", v2]
        end

      else
        # TODO add StandardError class
        raise "Data structure invalid at '#{k}': only Hash and Array members are permitted"
      end
    end

    diffs
  end

  def self.patch(hash, diffs)
    result = hash.dup

    diffs.each do |diff|
      flag, key, v1, v2 = diff
      if key =~ /\[/
        keyname, is_array, index = key.match(/^(.*)(\[)(.*)\]$/).captures
      elsif key =~ /\./
        keyname, subkey = key.match(/^(.*)\.(.*)$/).captures
      else
        keyname = key
      end

      case flag
      when '~'
        # change a value in place

        if subkey
          result[keyname][subkey] = v2
        else
          result[keyname] = v2
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
          result[keyname].delete_at(index.to_i)
        else
          result.delete(keyname)
        end
      end
    end

    result.delete_if {|k,v| v.nil? || v.empty?}

    result
  end
end
