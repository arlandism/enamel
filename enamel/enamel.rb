module Enamel

  VERSION = "0.0.1"

  require "lib/cache"

  def self.call(env)
    Cache.response(env)
  end

end
