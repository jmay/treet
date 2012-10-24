# encoding: UTF-8
require "test_helper"
require "pp"

describe Treet::Gitfarm do
  def make_gitfarm
    Treet::Gitfarm.plant(
      :json => jsonfile('master'),
      :root => Dir.mktmpdir('farm', $topdir),
      :author => {:name => 'Bob', :email => 'bob@example.com'}
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
  end

  describe "new repos in existing farms" do
    subject do
      farm = make_gitfarm
      farm.add(load_json('bob1'), :tag => "source1")
      farm
    end

    it "can be tagged" do
      bob = subject.repos.select {|id, repo| repo.to_hash['name']['first'] == 'Bob'}.values.first
      bob.wont_be_nil
      bob.tags.first.name.must_equal 'refs/tags/source1'
    end
  end
end
