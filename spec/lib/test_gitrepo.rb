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
        puts "MAKE FOR JOHNB"
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
  end

  describe "a gitrepo with an xref" do
    subject do
      make_gitrepo('one',
        :author => {:name => 'Bob', :email => 'bob@example.com'},
        :xrefkey => 'foo',
        :xref => 'bar')
    end
  end

  describe "a patched gitrepo" do
    def self.patch_johnb
      @memo ||= begin
        puts "MAKE & PATCH FOR JOHNB"
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
    subject do
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
      subject.index.count.must_equal 2
      subject.entries.must_include 'name'
      subject.entries.grep(/emails/).wont_be_empty
    end

    it "should hashify correctly" do
      # should reflect the deletion in current state
      expectation = load_json('two')
      expectation['emails'].delete_if {|v| v['label'] == 'home'}
      subject.to_hash.must_equal expectation
    end

    it "should have 2 commits" do
      r = Rugged::Repository.new(subject.root)
      latest_commit = r.head.target
      r.lookup(latest_commit).parents.count.must_equal 1
      previous_commit = r.lookup(latest_commit).parents.first
      previous_commit.parents.must_be_empty
    end

    it "should show the original state in the previous commit" do
      r = Rugged::Repository.new(subject.root)
      latest_commit = r.head.target
      r.lookup(latest_commit).parents.count.must_equal 1
      previous_commit = r.lookup(latest_commit).parents.first
      assert hashalike(subject.to_hash(:commit => previous_commit.oid), load_json('two'))
    end
  end

  describe "a tagged & patched repo" do
    subject do
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

    it "should correctly commit the existing updated git artifacts" do
      subject.to_hash(:commit => subject.head.target)['name']['first'].must_equal 'Ralph'
    end

    it "should not have an index entry for the removed item" do
      subject.entries.must_include 'name'
      subject.entries.grep(/^emails/).wont_be_empty
      subject.index.count.must_equal 2
    end

    it "should have tag not pointing to HEAD" do
      subject.tags.count.must_equal 1
      subject.tags.first.name.must_equal "refs/tags/app1"
      subject.tags.first.target.wont_equal subject.head.target
    end

    it "should have the original image for the tag" do
      refute hashalike(subject.to_hash, subject.to_hash(:tag => 'app1'))
      assert hashalike(subject.to_hash(:tag => 'app1'), load_json('two'))
    end

    it "should have no branches" do
      subject.branches.must_be_empty
    end
  end

  describe "a tagged repo" do
    subject do
      r = make_gitrepo('two', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.tag('source1')
      r
    end

    it "should have tags" do
      subject.tags.count.must_equal 1
      subject.tags.first.name.must_equal "refs/tags/source1"
    end

    it "should have no branches" do
      subject.branches.must_be_empty
    end

    it "should retrieve same image for default and by tag" do
      assert hashalike(subject.to_hash(:tag => 'source1'), load_json('two'))
    end

    it "should point the tag at the commit" do
      subject.tags.first.target.must_equal subject.head.target
    end
  end

  describe "a multiply-patched gitrepo" do
    subject do
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

    it "should remember all the tags" do
      subject[:repo].tags.count.must_equal 4
    end

    it "should fetch different images by tag" do
      assert hashalike(subject[:repo].to_hash(:tag => 'app1'), subject[:image1])
      assert hashalike(subject[:repo].to_hash(:tag => 'app2'), subject[:image2])
      assert hashalike(subject[:repo].to_hash(:tag => 'app3'), subject[:image3])
      assert hashalike(subject[:repo].to_hash(:tag => 'app4'), subject[:image4])
      assert hashalike(subject[:repo].to_hash, subject[:image4])
    end
  end

  describe "a branched gitrepo" do
    subject do
      r = make_gitrepo('one', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.branch('mybranch')
      r
    end

    it "should show a branch" do
      subject.branches.must_equal ['refs/heads/mybranch']
    end
  end
end
