# encoding: UTF-8

require "uuidtools"

class Treet::Farm
  attr_reader :repos, :root, :xrefkey

  def initialize(opts)
    raise Errno::ENOENT unless File.directory?(opts[:root])

    @root = opts[:root]
    @xrefkey = opts[:xref]

    @repos = {}
    Dir.glob("#{root}/*").each do |subdir|
      # in a Farm we are looking for repositories under the root
      if File.directory?(subdir)
        xref = File.basename(subdir)
        @repos[xref] = Treet::Repo.new(subdir, :xrefkey => xrefkey, :xref => xref)
      end
    end
  end

  # export as an array, not as a hash
  # the xref for each repo will be included under `xref.{xrefkey}`
  def export
    repos.map {|xref,repo| repo.to_hash}
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

  # apply patches to a farm of repos
  def patch(patches)
    patches.map do |k,diffs|
      repos[k].patch(diffs)
    end
  end

  def [](xref)
    repos[xref]
  end
end
