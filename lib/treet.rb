unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

%w(version hash repo farm gitrepo).each do |f|
  require_relative "treet/#{f}"
end
