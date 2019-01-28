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
      {
        'Content-Type' => media_type,
        'User-Agent' => env['HTTP_USER_AGENT'],
        'X-Forwarded-For' => env['HTTP_X_FORWARDED_FOR'],
      }.select{|k,v| !v.nil? }
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
      [ 400, {}, [exception.to_s] ]
    end
  end
end

Rack::Server.start(
  app: HttpProxy.new, Port: 8000
)
