# encoding: UTF-8
require "test_helper"
require "pp"

describe Treet::Gitfarm do
  describe "a directory of labeled git repos" do
    subject do
      Treet::Gitfarm.plant(
        :json => jsonfile('master'),
        :root => Dir.mktmpdir('farm', $topdir),
        :author => {:name => 'Bob', :email => 'bob@example.com'}
      )
    end

    it "should all be gitified" do
      subject.repos.each do |id, repo|
        repo.tags.must_be_empty
      end
    end
  end
end
