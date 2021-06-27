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
      # @param is_authenticated [#call]
      #   predicate for deciding when the request should be checked
      def initialize(app, is_authenticated: ->(env) { true })
        @app = app

        @is_authenticated = is_authenticated
      end

      # @param env [Hash]
      #
      # @param [Array<Integer, Hash{String => String}, Array<String>]
      def call(env)
        CheckHeader.new.(env) if @is_authenticated.(env)

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
