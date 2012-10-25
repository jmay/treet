unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

%w(version hash repo farm).each do |f|
  require_relative "treet/#{f}"
end

# under MacRuby 0.12, the `rugged` gem causes seg fault, sometimes merely on require()
unless defined? MACRUBY_VERSION
  %w(gitrepo gitfarm).each do |f|
    require_relative "treet/#{f}"
  end
end
