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
  def make_gitrepo(filename, opts = {})
    thash = Treet::Hash.new(load_json(filename))
    trepo = thash.to_repo(Dir.mktmpdir('repo', $topdir))
    Treet::Gitrepo.new(trepo.root, opts)
  end

  def hashalike(h1, h2)
    Treet::Hash.diff(h1, h2)
  end

  describe "creation" do
    it "must have an author" do
      ->{ make_gitrepo('one') }.must_raise ArgumentError, "xxx"
    end

    # TODO: must have an existing & non-empty directory tree
  end

  describe "a minimal non-empty untagged gitrepo" do
    subject { make_gitrepo('one', :author => {:name => 'Bob', :email => 'bob@example.com'}) }

    it "should have exactly one commit" do
      subject.head.wont_be_nil
      subject.refs.count.must_equal 1
      subject.refs.first.target.must_equal subject.head.target
      r = Rugged::Repository.new(subject.root)
      r.lookup(subject.head.target).parents.must_be_empty
    end

    it "should fetch data content" do
      subject.to_hash.must_equal load_json('one')
    end

    it "should have no tags" do
      subject.tags.must_be_empty
    end

    it "should fail on unknown tag lookups" do
      ->{subject.to_hash(:tag => 'nosuchtag')}.must_raise ArgumentError
    end
  end

  describe "a patched gitrepo" do
    subject do
      r = make_gitrepo('one', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.patch([
        [
          "+",
          "org.name",
          "Bigcorp"
        ]
      ])
      r
    end

    it "should hashify correctly" do
      expectation = load_json('one').merge({'org' => {'name' => 'Bigcorp'}})
      subject.to_hash.must_equal expectation
    end

    it "should have 2 commits" do
      r = Rugged::Repository.new(subject.root)
      latest_commit = r.head.target
      r.lookup(latest_commit).parents.count.must_equal 1
      previous_commit = r.lookup(latest_commit).parents.first
      previous_commit.parents.must_be_empty
    end

    it "should have no tags" do
      subject.tags.must_be_empty
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

  describe "a tagged repo" do
    subject do
      r = make_gitrepo('two', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.tag('source1')
      r.patch([
        [
          "-",
          "emails[]",
          { "label" => "home", "email" => "johns@lectroid.com" }
        ]
      ])
      r
    end

    it "should have tag not pointing to HEAD" do
      subject.tags.count.must_equal 1
      subject.tags.first.name.must_equal "refs/tags/source1"
      subject.tags.first.target.wont_equal subject.head.target
    end

    it "should have the original image for the tag" do
      subject.to_hash.wont_equal subject.to_hash(:tag => 'source1')
      assert hashalike(subject.to_hash(:tag => 'source1'), load_json('two'))
    end
  end

  describe "a tagged patch" do
    subject do
      r = make_gitrepo('two', :author => {:name => 'Bob', :email => 'bob@example.com'})
      r.tag('source1')
      r
    end

    it "should have tags" do
      subject.tags.count.must_equal 1
      subject.tags.first.name.must_equal "refs/tags/source1"
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
      @image1 = r.to_hash
      r.patch([
        [
          "-",
          "emails[]",
          { "label" => "home", "email" => "johns@lectroid.com" }
        ]
      ])
      r.tag('app2')
      @image2 = r.to_hash
      r.patch([
        [
          "+",
          "org.name",
          "BigCorp"
        ]
      ])
      r.tag('app3')
      @image3 = r.to_hash
      r
    end

    it "should remember all the tags" do
      subject.tags.count.must_equal 3
    end

    it "should fetch different images by tag" do
      assert hashalike(subject.to_hash(:tag => 'app1'), @image1)
      assert hashalike(subject.to_hash(:tag => 'app2'), @image2)
      assert hashalike(subject.to_hash(:tag => 'app3'), @image3)
    end
  end
end
