require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

require File.expand_path('../../lib/treet', __FILE__)

require "tmpdir"
require "fileutils"

RSpec.configure do |config|
end
