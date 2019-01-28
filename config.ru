# frozen_string_literal: true
require 'rubygems'
require 'bundler'
Bundler.require

# Monkey-patching Rack::Request to add custom helper methods
module Rack
  class Request
    def supported_method?
      get? || post?
    end

    def valid?
      path_info.start_with?(
        '/proxy/',
      ) && supported_method?
    end

    def request_headers
      headers = {}
      user_agent = env['HTTP_USER_AGENT']
      forwarded_for = env['HTTP_X_FORWARDED_FOR']
      content_type = media_type
      headers['Content-Type'] = content_type if content_type
      headers['User-Agent'] = user_agent if user_agent
      headers['X-Forwarded-For'] = forwarded_for if forwarded_for
      headers
    end
  end
end

class HttpProxy
  def initialize
    @patron_pool = ConnectionPool.new(size: 200, timeout: 15) do
      Patron::Session.new do |s|
        s.timeout = 1200
        s.connect_timeout = 5
      end
    end
  end

  def call(env)
    begin
      req = Rack::Request.new(env)
      if req.valid?
        url = req.path_info[7..-1]
        url += "?#{req.query_string}" unless req.query_string.empty?
        body = req.body.read
        options = body.nil? ? {} : { data: body, multipart: false }
        @patron_pool.with do |session|
          response = session.request req.request_method, url, req.request_headers, options
          remapped_headers = response.headers.select{|k,v| k != "Transfer-Encoding"}
                                             .map {|k,v| [k, v.respond_to?(:join) ? v.join(",") : v] }
          [response.status, remapped_headers, [response.body]]
        end
      else
        [ 400, {}, ["Unsupported URL"] ]
      end
    rescue => exception
      $stderr.puts exception.inspect
      [ 400, {}, [exception] ]
    end
  end
end

require 'rack/show_exceptions'
Rack::Server.start(
  app: Rack::ShowExceptions.new(Rack::Lint.new(HttpProxy.new)), Port: 8000
)
