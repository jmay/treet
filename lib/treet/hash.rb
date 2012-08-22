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
            File.open("#{k}/#{i}", "w") {|f| f << v2.to_json}
          end

        else
          raise "Unsupported object type #{v.class} for '#{k}'"
        end
      end
    end
  end

  def normalize(hash)
    hash.each_with_object({}) do |(k,v),h|
      if v.is_a?(Array)
        h[k] = v.sort do |a,b|
          a.to_a.sort_by(&:first).flatten <=> b.to_a.sort_by(&:first).flatten
        end
      else
        h[k] = v
      end
    end
  end

  def self.diff(hash1, hash2)
    diffs = []

    hash1.each do |k,v|
      if hash2.include?(k)
        case v
        when Hash
          v1 = hash1[k]
          v2 = hash2[k]

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
          a1 = hash1[k]
          a2 = hash2[k]

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
      else
        diffs << ['+', k, v]
      end
    end

    diffs
  end
end
