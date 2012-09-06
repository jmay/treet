unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative "treet/version"

require_relative "treet/repo"
require_relative "treet/hash"
require_relative "treet/farm"
