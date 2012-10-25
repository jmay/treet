# encoding: UTF-8
require "test_helper"
require "pp"

describe Treet::Gitfarm do
  def self.empty_gitfarm
    f = Treet::Gitfarm.new(
      :root => Dir.mktmpdir('farm', $topdir),
      :xref => 'testapp',
      :author => {:name => 'Bob', :email => 'bob@example.com'}
    )
    # puts "MADE AN EMPTY FARM OF #{f.repotype}"
    f
  end

  def make_gitfarm
    f = Treet::Gitfarm.plant(
      :json => jsonfile('master'),
      :root => Dir.mktmpdir('farm', $topdir),
      :author => {:name => 'Bob', :email => 'bob@example.com'},
      :xref => 'myapp'
    )
    # puts "MADE A LOADED FARM OF #{f.repotype}"
    f
  end

  describe "a directory of labeled git repos" do
    let(:farm) { make_gitfarm }

    it "should be populated" do
      farm.repos.count.must_equal 3
    end

    it "should all be gitified" do
      farm.repos.each do |id, repo|
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
      subject.must_be_instance_of Treet::Gitfarm
      bob = subject.repos.values.first
      bob.wont_be_nil
      bob.must_be_instance_of Treet::Gitrepo
      bob.tags.first.name.must_equal 'refs/tags/app1'
    end

    # it "carries xref in data representation but not in git" do
    #   id, bob = subject.repos.first
    #   bob.to_hash['xref']['testapp'].must_equal id
    # end
  end
end
