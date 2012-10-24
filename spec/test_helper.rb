require 'minitest/spec'

require File.expand_path('../../lib/treet', __FILE__)

require "tmpdir"
require "fileutils"

$topdir ||= Dir.mktmpdir("treet-tests-")

def jsonfile(filename)
  "#{File.dirname(__FILE__)}/json/#{filename}.json"
end

def load_json(filename)
  JSON.load(File.open(jsonfile(filename)))
end

MiniTest::Unit.after_tests do
  $stderr.puts "Erasing #{$topdir}"
  FileUtils.rm_rf $topdir
  $topdir = nil
end

# MUST PUT THIS AT *END* OF FILE OR CLEANUP WILL HAPPEN BEFORE TESTS ARE RUN!
require 'minitest/autorun'
