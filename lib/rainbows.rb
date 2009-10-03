# -*- encoding: binary -*-
require 'unicorn'

def Rainbows!(&block)
  block_given? or raise ArgumentError, "Rainbows! requires a block"
  Rainbows::HttpServer.setup(block)
end

module Rainbows

  require 'rainbows/const'
  require 'rainbows/http_server'
  require 'rainbows/http_response'

  autoload :Revactor, 'rainbows/revactor'
  autoload :ThreadBase, 'rainbows/thread_base'
  autoload :ThreadPool, 'rainbows/thread_pool'

  class << self
    def run(app, options = {})
      HttpServer.new(app, options).start.join
    end
  end

end
