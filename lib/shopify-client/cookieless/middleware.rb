# frozen_string_literal: true

require 'json'

module ShopifyClient
  module Cookieless
    # Rack middleware implementing cookieless authentication with App Bridge
    # session tokens.
    #
    # Returns a 401 response if a request is unauthorised.
    class Middleware
      # @param app [#call]
      # @param should_check [#call]
      #   predicate for deciding when the request should be checked
      def initialize(app, should_check: ->(env) { true })
        @app = app

        @should_check = should_check
      end

      # @param env [Hash]
      #
      # @param [Array<Integer, Hash{String => String}, Array<String>]
      def call(env)
        CheckHeader.new.(env) if @should_check.(env)

        @app.call(env)
      rescue UnauthorisedError
        Rack::Response.new do |response|
          response.status = 401
          response.set_header('Content-Type', 'application/json')
          response.write({
            error: 'Invalid session token',
          }.to_json)
        end.to_a
      end
    end
  end
end
