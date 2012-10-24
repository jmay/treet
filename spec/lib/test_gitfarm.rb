# encoding: UTF-8
require "test_helper"
require "pp"

describe Treet::Gitfarm do
  def self.empty_gitfarm
    puts "EMPTY FARM"
    Treet::Gitfarm.new(
      :root => Dir.mktmpdir('farm', $topdir),
      :xref => 'testapp',
      :author => {:name => 'Bob', :email => 'bob@example.com'}
    )
  end

  def make_gitfarm
    puts "MAKE FARM"
    Treet::Gitfarm.plant(
      :json => jsonfile('master'),
      :root => Dir.mktmpdir('farm', $topdir),
      :author => {:name => 'Bob', :email => 'bob@example.com'},
      :xref => 'myapp'
    )
  end

  describe "a directory of labeled git repos" do
    subject { make_gitfarm }

    it "should all be gitified" do
      subject.repos.each do |id, repo|
        repo.head.wont_be_nil
        repo.tags.must_be_empty
      end
    end

    # it "should all include xref when fetched" do
    #   subject.repos.each do |id, repo|
    #     repo.to_hash['xref'].keys.must_include 'myapp'
    #   end
    # end
  end

  describe "new repo in empty farm" do
    def self.dofarm
      @farm ||= begin
        farm = empty_gitfarm
        farm.add(load_json('bob1'), :tag => "app1")
        farm
      end
    end

    subject { self.class.dofarm }
    # subject do
    #   farm = empty_gitfarm
    #   farm.add(load_json('bob1'), :tag => "app1")
    #   farm
    # end

    it "is the only repo" do
      subject.repos.count.must_equal 1
    end

    it "can be tagged" do
      bob = subject.repos.values.first
      bob.wont_be_nil
      bob.tags.first.name.must_equal 'refs/tags/app1'
    end

    # it "carries xref in data representation but not in git" do
    #   id, bob = subject.repos.first
    #   bob.to_hash['xref']['testapp'].must_equal id
    # end
  end
end
