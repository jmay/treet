# encoding: UTF-8

class Treet::Gitfarm < Treet::Farm
  attr_reader :author

  def initialize(opts)
    raise ArgumentError, "No git farm without an author for commits" unless opts[:author]
    super
    @repotype = Treet::Gitrepo
    @author = opts[:author]
  end

  def self.plant(opts)
    super(opts.merge(:repotype => Treet::Gitrepo))
  end

  def repos
    super(:author => author)
  end

  def repo(id, opts = {})
    super(id, opts.merge(:author => author))
  end

  def add(hash, opts = {})
    repo = super(hash, opts.merge(:author => author))
    if opts[:tag]
      repo.tag(opts[:tag])
    end
    repo
  end
end
