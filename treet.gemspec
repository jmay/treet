# -*- encoding: utf-8 -*-
require File.expand_path('../lib/treet/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jason May"]
  gem.email         = ["jmay@pobox.com"]
  gem.description   = %q{Transform between trees of files and JSON blobs}
  gem.summary       = %q{Transform between trees of files and JSON blobs}
  gem.homepage      = ""
  gem.license       = "LGPL-3"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "treet"
  gem.require_paths = ["lib"]
  gem.version       = Treet::VERSION

  gem.add_dependency 'map'
  gem.add_dependency 'thor'
  gem.add_dependency 'rugged', "~> 0.19.0"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency "guard-minitest"
  gem.add_development_dependency "ruby_gntp"
  gem.add_development_dependency "rb-fsevent"
end
