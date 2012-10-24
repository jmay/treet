# encoding: UTF-8

require "rugged"
require "forwardable"

class Treet::Gitrepo < Treet::Repo
  extend Forwardable
  def_delegators :@gitrepo, :head, :refs, :index

  def initialize(path, opts = {})
    raise ArgumentError, "author required for updates" unless opts[:author]
    super

    @author = opts[:author]

    begin
      @gitrepo = Rugged::Repository.new(root)
    rescue Rugged::RepositoryError
      @gitrepo = initialize_gitrepo
      add_and_commit!
    end
  end

  def tags
    gitrepo.refs(/tags/)
  end

  def tag(tagname)
    refname = "refs/tags/#{tagname}"
    begin
      if tag_ref = Rugged::Reference.lookup(gitrepo, refname)
        # move an existing tag
        tag_ref.target = head.target
      else
        # new tag
        Rugged::Reference.create(gitrepo, refname, head.target)
      end
    rescue Rugged::ReferenceError
      # invalid string for source, e.g. blank or illegal punctuation (colons)
      raise ArgumentError "invalid source string '#{tagname}' for repository tagging"
    end
  end

  def patch(patchdef)
    super
    add_and_commit!
  end

  def to_hash(opts = {})
    if opts[:commit]
      snapshot(opts[:commit])
    elsif opts[:tag]
      tag_snapshot(opts[:tag])
    else
      # snapshot(head.target)
      super()
    end
  end

  def entries
    index.entries.map{|e| e[:path]}
  end

  def branches
    refs(/heads/).map(&:name) - ['refs/heads/master']
  end

  # always branch from tip of master (private representation)
  def branch(name)
    Rugged::Reference.create(gitrepo, "refs/heads/#{name}", head.target)
  end


  private

  attr_reader :gitrepo, :author

  def initialize_gitrepo
    Rugged::Repository.init_at(root, false)
  end

  # always commits to HEAD
  def commit!(sha)
    parent_shas = begin
      [gitrepo.head.target]
    rescue Rugged::ReferenceError
      # this is the first commit
      []
    end

    authorship = author.merge(:time => Time.now)

    sha = Rugged::Commit.create(gitrepo,
      :message => "",
      :author => authorship,
      :committer => authorship,
      :parents => parent_shas,
      :tree => sha,
      :update_ref => "HEAD"
    )

    sha
  end

  def add_and_commit!
    current_index = entries
    Dir.chdir(root) do
      current_files = Dir.glob('**/*')

      # additions
      (current_files - current_index).each do |file|
        # must add each filename explicitly, `index#add` does not recurse into directories
        if File.file?(file)
          index.add(file)
        end
      end

      # possible alterations - these changes won't be detected unless we explicitly git-add
      (current_files & current_index).each do |file|
        if File.file?(file)
          index.add(file)
        end
      end

      # deletions
      (current_index - current_files).each do |file|
        # `index#remove` handles directories
        index.remove(file)
      end
    end

    index.write
    tree_sha = index.write_tree
    commit!(tree_sha)
  end

  def snapshot(commit_sha)
    commit = gitrepo.lookup(commit_sha)
    tree = commit.tree
    # must traverse the tree: entries are files or subtrees
    data = {}
    tree.each do |obj|
      data[obj[:name]] = case obj[:type]
      when :blob
        JSON.load(gitrepo.read(obj[:oid]).data)
      when :tree
        gitrepo.lookup(obj[:oid]).each_with_object([]) do |subobj,d|
          d << JSON.load(gitrepo.read(subobj[:oid]).data)
        end
      else
        raise TypeError, "UNRECOGNIZED GIT OBJECT TYPE #{obj[:type]}"
      end
    end

    # decorate(data)
    data
  end

  def tag_snapshot(tagname)
    tag_ref = Rugged::Reference.lookup(gitrepo, "refs/tags/#{tagname}")
    raise ArgumentError, "tag '#{tagname}' does not exist in this repo" unless tag_ref
    snapshot(tag_ref.target)
  end
end
