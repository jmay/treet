# encoding: UTF-8

class Treet::Farm
  attr_reader :repos, :root, :xref

  def initialize(opts)
    @root = opts[:root]
    @xref = opts[:xref]

    @repos = Dir.glob("#{root}/*").map do |subdir|
      Treet::Repo.new(subdir, :xref => File.basename(subdir))
    end
  end

  def export
    repos.map {|repo| repo.to_hash(:xref => @xref)}
  end

  def self.plant(opts)
    jsonfile = opts[:json]
    rootdir = opts[:root]

    array_of_hashes = JSON.load(File.open(jsonfile))
    Dir.chdir(rootdir) do
      array_of_hashes.each do |h|
        uuid = UUIDTools::UUID.random_create.to_s
        thash = Treet::Hash.new(h)
        repo = thash.to_repo(uuid)
      end
    end

    Treet::Farm.new(:root => rootdir, :xref => opts[:xref])
  end
end
