# -*- encoding: binary -*-
# :enddoc:
module Rainbows::Const

  RAINBOWS_VERSION = '3.0.0'

  include Unicorn::Const

  RACK_DEFAULTS = Unicorn::HttpRequest::DEFAULTS.update({
    "SERVER_SOFTWARE" => "Rainbows! #{RAINBOWS_VERSION}",

    # using the Rev model, we'll automatically chunk pipe and socket objects
    # if they're the response body.  Unset by default.
    # "rainbows.autochunk" => false,
  })

  # client IO object that supports reading and writing directly
  # without filtering it through the HTTP chunk parser.
  # Maybe we can get this renamed to "rack.io" if it becomes part
  # of the official spec, but for now it is "hack.io"
  CLIENT_IO = "hack.io".freeze

  RACK_INPUT = Unicorn::HttpRequest::RACK_INPUT
  REMOTE_ADDR = Unicorn::HttpRequest::REMOTE_ADDR
end
