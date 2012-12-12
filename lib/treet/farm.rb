# encoding: UTF-8

require "securerandom"

class Treet::Farm
  attr_reader :root, :xrefkey, :repotype

  def initialize(opts)
    raise Errno::ENOENT unless File.directory?(opts[:root])

    @root = opts[:root]
    @xrefkey = opts[:xref]
    @repotype = opts[:repotype] || Treet::Repo
  end

  def repos(opts = {})
    @repos_cache ||= Dir.glob("#{root}/*").each_with_object({}) do |subdir,h|
      # in a Farm we are looking for repositories under the root
      if File.directory?(subdir)
        xref = File.basename(subdir)
        h[xref] = repotype.new(subdir, opts.merge(:xrefkey => xrefkey, :xref => xref))
      end
    end
  end

  def reset
    @repos_cache = nil
  end

  # export as an array, not as a hash
  # the xref for each repo will be included under `xref.{xrefkey}`
  def export
    repos.map {|xref,repo| repo.to_hash}
  end

  # "plant" a new farm: given an array of hashes (in JSON), create a directory
  # of Treet repositories, one per hash. Generate directory names for each repo.
  def self.plant(opts)
    jsonfile = opts[:json]
    rootdir = opts[:root]

    array_of_hashes = JSON.load(File.open(jsonfile))
    Dir.chdir(rootdir) do
      array_of_hashes.each do |h|
        uuid = SecureRandom.uuid
        thash = Treet::Hash.new(h)
        thash.to_repo(uuid, opts)
      end
    end

    self.new(opts)
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

  # add a new repo, with data from an input hash
  # if an :id is provided, then the new repo will be stored under that directory name,
  # otherwise a unique id will be generated
  def add(hash, opts = {})
    uuid = opts[:id] || SecureRandom.uuid
    thash = Treet::Hash.new(hash)
    repos[uuid] = thash.to_repo("#{root}/#{uuid}", opts.merge(:repotype => repotype))
  end
end
