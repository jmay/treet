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

  def tag(tagname, opts = {})
    refname = "refs/tags/#{tagname}"
    commit = opts[:commit] || head.target
    if tag_ref = Rugged::Reference.lookup(gitrepo, refname)
      # move an existing tag
      tag_ref.target = commit
    else
      # new tag
      Rugged::Reference.create(gitrepo, refname, commit)
    end
  rescue Rugged::ReferenceError, Rugged::InvalidError => e
    # invalid string for source, e.g. blank or illegal punctuation (colons)
    # or opts[:commit] is invalid
    raise ArgumentError, "unable to tag '#{tagname}' on repo: #{e.message}"
  end

  def detag(tagname)
    if tag_ref = Rugged::Reference.lookup(gitrepo, "refs/tags/#{tagname}")
      tag_ref.delete!
    end
  end

  def patch(patchdef)
    super
    if git_changes?(patchdef)
      add_and_commit!
    end
  end

  def to_hash(opts = {})
    if opts[:commit]
      snapshot(opts[:commit])
    elsif opts[:tag]
      tag_snapshot(opts[:tag])
    else
      super()
    end.merge(augmentation)
  end

  def entries
    index.entries.map{|e| e[:path]}
  end

  def branches
    refs(/heads/).map {|ref| ref.name.gsub(/^refs\/heads\//, '')} - ['master']
  end

  # always branch from tip of master (private representation)
  def branch(name)
    Rugged::Reference.create(gitrepo, "refs/heads/#{name}", head.target)
  end

  def tagged?(tagname)
    ! commit_id_for(tagname).nil?
  end

  def version(opts = {})
    if tagname = opts[:tag]
      commit_id_for(tagname)
    else
      head.target
    end
  end

  def current?(tagname)
    commit_id_for(tagname) == head.target
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
      # automatically ignores dotfiles
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

      index.write
      tree_sha = index.write_tree
      commit!(tree_sha)
    end
  end

  def gitget(obj)
    data = gitrepo.read(obj[:oid]).data
    begin
      JSON.load(data)
    rescue JSON::ParserError
      # parser errors are not fatal
      # this just indicates a string entry rather than a hash
      data.empty? ? obj[:name] : data
    end
  end

  def snapshot(commit_sha)
    commit = gitrepo.lookup(commit_sha)
    tree = commit.tree
    # must traverse the tree: entries are files or subtrees
    data = {}
    tree.each do |obj|
      data[obj[:name]] = case obj[:type]
      when :blob
        gitget(obj)
      when :tree
        gitrepo.lookup(obj[:oid]).each_with_object([]) do |subobj,d|
          d << gitget(subobj)
        end
      else
        raise TypeError, "UNRECOGNIZED GIT OBJECT TYPE #{obj[:type]}"
      end
    end

    Treet::Hash.new(data)
  end

  def commit_id_for(tagname)
    (ref = Rugged::Reference.lookup(gitrepo, "refs/tags/#{tagname}")) && ref.target
  end

  def tag_snapshot(tagname)
    if commitid = version(:tag => tagname)
      snapshot(commitid)
    else
      # this tag does not appear in the repo; this is NOT an exception
      {}
    end
  end

  def augmentation(path = root)
    dotfiles = Dir.entries(path).select {|f|  f =~ /^\./ && f !~ /^(\.|\.\.|\.git)$/}
    dotfiles.each_with_object({}) {|f,h| h[f] = expand_json("#{path}/#{f}")}
  end

  # any patches in here that affect anything that must be recorded in git?
  def git_changes?(patchdef)
    patchdef.find {|p| p[1] =~ /^[^.]/}
  end
end
