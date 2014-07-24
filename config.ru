require 'rubygems'
require 'sinatra'

module Rack
  class CommonLogger
    def call(env)
      # do nothing
      @app.call(env)
    end
  end
end

require './app'
run App
