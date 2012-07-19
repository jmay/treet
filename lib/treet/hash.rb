# encoding: UTF-8

require "json"

class Treet::Hash
  attr_reader :data

  def initialize(jsonfile)
    @data = JSON.load(File.read(jsonfile))
  end

  def to_repo(root)
    construct(data, root)
  end

  def compare(repo)
    HashDiff.diff(data, repo.to_hash)
  end

  private

  def construct(data, filename)
    case data
    when Hash
      unless filename == '.'
        Dir.mkdir(filename) rescue nil
      end
      Dir.chdir(filename) do
        data.each do |name,body|
          construct(body,name)
        end
      end
    else
      File.open(filename, "w") {|f| f << data}
    end
  end
end
