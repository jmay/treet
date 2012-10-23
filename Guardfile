# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})

  watch(%r{^lib/treet/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard 'minitest' do
  # with Minitest::Unit
  # watch(%r{^spec/lib/test_.*\.rb})
  # watch(%r|^test/test_helper\.rb|)    { "test" }

  # watch(%r|^test/(.*)\/?test_(.*)\.rb|)
  # watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  # watch(%r{^lib/(.*)/entity\.rb$})     { "test" }

  # watch(%r|^lib/otherbase/contacts?.rb|)  { "test" }

  # with Minitest::Spec
  watch(%r|^spec/lib/test_(.*)\.rb|)
  watch(%r{^lib/treet/(.+)\.rb$})     { |m| "spec/lib/test_#{m[1]}.rb" }
  # watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  # watch(%r|^spec/spec_helper\.rb|)    { "spec" }
end
