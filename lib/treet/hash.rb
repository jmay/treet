# encoding: UTF-8

require "json"

class Treet::Hash
  attr_reader :data

  # when loading an Array (at the top level), members are always sorted
  # so that array comparisons will be order-independent
  def initialize(jsonfile)
    d = JSON.load(File.read(jsonfile))
    # convert Arrays to Sets
    # @data = d.each_with_object({}) {|(k,v),h| h[k] = v.is_a?(Array) ? v.to_set : v}
    @data = d.each_with_object({}) {|(k,v),h| h[k] = v.is_a?(Array) ? v.sort_by(&:hash) : v}
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

    # case data
    # when String
    #   File.open(filename, "w") {|f| f << data}
    # when Hash
    #   unless filename == '.'
    #     Dir.mkdir(filename) rescue nil
    #   end
    #   Dir.chdir(filename) do
    #     data.each do |name,body|
    #       File.open(name, "w") {|f| f << body.to_json}
    #       # construct(body,name)
    #     end
    #   end
    # when Array #, Set
    #   Dir.mkdir(filename)
    #   Dir.chdir(filename) do
    #     data.each_with_index do |v, i|
    #       File.open(i.to_s, "w") {|f| f << v.to_json}
    #     end
    #   end
    # else
    #   raise "Unsupported object type #{data.class} for #{filename}"
    # end
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
            diffs << ['-', "#{k}.#{k2}"]
          end
          (v1.keys & v2.keys).each do |k2|
            if v1[k2] != v2[k2]
              # altered sub-elements
              diffs << ['~', "#{k}.#{k2}", v2[k2]]
            end
          end

        when Array
          # assume that arrays have been sorted per `initialize` above
          a1 = hash1[k]
          a2 = hash2[k]

          a1.each_with_index do |v1, i|
            if !a2.include?(v1)
              # element has been removed
              diffs << ['-', "#{k}[#{i}]"]
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
