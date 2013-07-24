# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'minitest', test_folders: 'spec', test_file_patterns: 'test_*.rb' do
  # with Minitest::Unit
  # watch(%r{^spec/lib/test_.*\.rb})

  # watch(%r|^test/(.*)\/?test_(.*)\.rb|)
  # watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "test/#{m[1]}test_#{m[2]}.rb" }

  # watch(%r|^lib/otherbase/contacts?.rb|)  { "test" }

  # with Minitest::Spec
  watch(%r|^spec/lib/test_(.*)\.rb|)
  watch(%r{^lib/treet/(.+)\.rb$})     { |m| "spec/lib/test_#{m[1]}.rb" }
  watch(%r|^spec/test_helper\.rb|)    { "spec" }
  # watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  # watch(%r|^spec/spec_helper\.rb|)    { "spec" }
end

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})

  watch(%r{^lib/treet/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
