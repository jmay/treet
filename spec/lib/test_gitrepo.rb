# encoding: UTF-8
require "test_helper"
require "pp"

# convert a hash to a gitrepo
# convert a plain repo to a gitrepo
# convert a gitrepo to a plain repo
# initialize a treet git from an existing gitrepo (with a treet::repo structure)
# patch a gitrepo (with commit) - verify commit structure
# pulling past snapshots

describe Treet::Gitrepo do
  def self.make_gitrepo(filename, opts = {})
    thash = Treet::Hash.new(load_json(filename))
    trepo = thash.to_repo(Dir.mktmpdir('repo', $topdir))
    Treet::Gitrepo.new(trepo.root, opts)
  end

  def make_gitrepo(filename, opts = {})
    self.class.make_gitrepo(filename, opts)
  end

  def hashalike(h1, h2)
    Treet::Hash.diff(h1, h2).empty?
  end

  describe "creation" do
    it "must have an author" do
      ->{ make_gitrepo('one') }.must_raise(ArgumentError, "xxx")
    end

    # TODO: must have an existing & non-empty directory tree
  end

  describe "a minimal non-empty untagged gitrepo" do
    def self.make_johnb
      @memo ||= begin
        data = {
          "name" => {
            "full" => "John Bigbooté"
          }
        }
        thash = Treet::Hash.new(data)
        trepo = thash.to_repo(Dir.mktmpdir('repo', $topdir))
        Treet::Gitrepo.new(trepo.root, :author => {:name => 'Bob', :email => 'bob@example.com'})
      end
    end

    let(:johnb) { self.class.make_johnb }

    it "should have exactly one commit" do
      johnb.head.wont_be_nil
      johnb.refs.count.must_equal 1
      johnb.refs.first.target.must_equal johnb.head.target
      r = Rugged::Repository.new(johnb.root)
      r.lookup(johnb.head.target).parents.must_be_empty
    end

    it "should have a single entry" do
      johnb.index.count.must_equal 1
      johnb.entries.must_equal ['name']
    end

    it "should fetch data content" do
      johnb.to_hash.must_equal load_json('one')
    end

    it "should have no tags" do
      johnb.tags.must_be_empty
    end

    it "should fail on unknown tag lookups" do
      ->{johnb.to_hash(:tag => 'nosuchtag')}.must_raise ArgumentError
    end

    it "should have no branches" do
      johnb.branches.must_be_empty
    end

    it "should return commit SHA for version label" do
      johnb.version.must_equal johnb.head.target
    end

    it "should return nil for unknown tag versions" do
      johnb.version(:tag => 'nosuchtag').must_be_nil
    end
  end


  describe "a patched gitrepo" do
    def self.patch_johnb
      @memo ||= begin
        data = {
          "name" => {
            "full" => "John Bigbooté"
          }
        }
        thash = Treet::Hash.new(data)
        trepo = thash.to_repo(Dir.mktmpdir('repo', $topdir))
        r = Treet::Gitrepo.new(trepo.root, :author => {:name => 'Bob', :email => 'bob@example.com'})
        r.patch([
          [
            "+",
            "org.name",
            "Bigcorp"
          ]
        ])
        r
      end
    end

    let(:repo) { self.class.patch_johnb }

    it "should have correct git index" do
      repo.index.count.must_equal 2
      repo.entries.must_include 'name'
      repo.entries.must_include 'org'
    end

    it "should hashify correctly" do
      expectation = load_json('one').merge({'org' => {'name' => 'Bigcorp'}})
      repo.to_hash.must_equal expectation
    end

    it "should have 2 commits" do
      r = Rugged::Repository.new(repo.root)
      latest_commit = r.head.target
      r.lookup(latest_commit).parents.count.must_equal 1
      previous_commit = r.lookup(latest_commit).parents.first
      previous_commit.parents.must_be_empty
    end

    it "should have no tags" do
      repo.tags.must_be_empty
    end

    # it "should be able to reverse-engineer the patch from the git history" do
    #   skip
    #   # rugged has a `Rugged::Commit#diff-tree` on the roadmap (see `USAGE.rb`), not yet implemented
    # end
  end

  describe "patched with a delete" do
    let(:repo) do
      r = make_gitrepo('two', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.patch([
        [
          "-",
          "emails[]",
          { "label" => "home", "email" => "johns@lectroid.com" }
        ]
      ])
      r
    end

    it "should have correct git index" do
      repo.index.count.must_equal 2
      repo.entries.must_include 'name'
      repo.entries.grep(/emails/).wont_be_empty
    end

    it "should hashify correctly" do
      # should reflect the deletion in current state
      expectation = load_json('two')
      expectation['emails'].delete_if {|v| v['label'] == 'home'}
      repo.to_hash.must_equal expectation
    end

    it "should have 2 commits" do
      r = Rugged::Repository.new(repo.root)
      latest_commit = r.head.target
      r.lookup(latest_commit).parents.count.must_equal 1
      previous_commit = r.lookup(latest_commit).parents.first
      previous_commit.parents.must_be_empty
    end

    it "should show the original state in the previous commit" do
      r = Rugged::Repository.new(repo.root)
      latest_commit = r.head.target
      r.lookup(latest_commit).parents.count.must_equal 1
      previous_commit = r.lookup(latest_commit).parents.first
      assert hashalike(repo.to_hash(:commit => previous_commit.oid), load_json('two'))
    end
  end

  describe "a tagged & patched repo" do
    def self.makerepo
      @repo ||= begin
        r = make_gitrepo('two',
          :author => {:name => 'Bob', :email => 'bob@example.com'},
          :xrefkey => 'app1',
          :xref => 'APP1_ID'
        )
        r.tag('app1')
        r.patch([
          [
            "-",
            "emails[]",
            { "label" => "home", "email" => "johns@lectroid.com" }
          ],
          [
            "+",
            "name.first",
            "Ralph"
          ]
        ])
        r
      end
    end

    let(:repo) { self.class.makerepo }

    it "should correctly commit the existing updated git artifacts" do
      repo.to_hash(:commit => repo.head.target)['name']['first'].must_equal 'Ralph'
    end

    it "should not have an index entry for the removed item" do
      repo.entries.must_include 'name'
      repo.entries.grep(/^emails/).wont_be_empty
      repo.index.count.must_equal 2
    end

    it "should have tag not pointing to HEAD" do
      repo.tags.count.must_equal 1
      repo.tags.first.name.must_equal "refs/tags/app1"
      repo.tags.first.target.wont_equal repo.head.target
    end

    it "should have the original image for the tag" do
      refute hashalike(repo.to_hash, repo.to_hash(:tag => 'app1'))
      assert hashalike(repo.to_hash(:tag => 'app1'), load_json('two'))
    end

    it "should have no branches" do
      repo.branches.must_be_empty
    end

    it "should track version label by tag" do
      repo.version.must_equal repo.head.target
      repo.version(:tag => 'app1').must_equal repo.tags.first.target
    end
  end

  describe "a tagged repo" do
    let(:repo) do
      r = make_gitrepo('two', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.tag('source1')
      r
    end

    it "should have tags" do
      repo.tags.count.must_equal 1
      repo.tags.first.name.must_equal "refs/tags/source1"
    end

    it "should have no branches" do
      repo.branches.must_be_empty
    end

    it "should retrieve same image for default and by tag" do
      assert hashalike(repo.to_hash(:tag => 'source1'), load_json('two'))
    end

    it "should point the tag at the commit" do
      repo.tags.first.target.must_equal repo.head.target
      repo.version.must_equal repo.version(:tag => 'source1')
    end
  end

  describe "a multiply-patched gitrepo" do
    def self.makerepo
      @repo ||= begin
        r = make_gitrepo('two', :author => {:name => 'Bob', :email => 'bob@example.com'})
        r.tag('app1')
        r.tag('app2')
        image1 = r.to_hash
        r.patch([
          [
            "+",
            "org.name",
            "BigCorp"
          ]
        ])
        r.tag('app2')
        image2 = r.to_hash
        r.patch([
          [
            "-",
            "org.name",
            "BigCorp"
          ]
        ])
        r.tag('app3')
        image3 = r.to_hash
        r.patch([
          [
            "-",
            "emails[]",
            { "label" => "home", "email" => "johns@lectroid.com" }
          ]
        ])
        r.tag('app4')
        image4 = r.to_hash

        {
          :repo => r,
          :image1 => image1,
          :image2 => image2,
          :image3 => image3,
          :image4 => image4
        }
      end
    end

    let(:repo) { self.class.makerepo }

    it "should remember all the tags" do
      repo[:repo].tags.count.must_equal 4
    end

    it "should fetch different images by tag" do
      assert hashalike(repo[:repo].to_hash(:tag => 'app1'), repo[:image1])
      assert hashalike(repo[:repo].to_hash(:tag => 'app2'), repo[:image2])
      assert hashalike(repo[:repo].to_hash(:tag => 'app3'), repo[:image3])
      assert hashalike(repo[:repo].to_hash(:tag => 'app4'), repo[:image4])
      assert hashalike(repo[:repo].to_hash, repo[:image4])
    end

    it "should have different version labels for each tag" do
      versions = ['app1', 'app2', 'app3', 'app4'].map {|s| repo[:repo].version(:tag => s)}
      versions.uniq.count.must_equal 4
    end
  end

  describe "a branched gitrepo" do
    let(:repo) do
      r = make_gitrepo('one', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.branch('mybranch')
      r
    end

    it "should show a branch" do
      repo.branches.must_equal ['mybranch']
    end
  end
end
