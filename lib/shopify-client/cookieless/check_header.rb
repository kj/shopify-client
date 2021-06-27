# frozen_string_literal: true

require 'json'

module ShopifyClient
  module Cookieless
    class CheckHeader
      UnauthorisedError = Class.new(Error)

      # @param rack_env [Hash]
      #
      # @raise [UnauthorisedError]
      def call(rack_env)
        header = rack_env['HTTP_AUTHORIZATION']

        raise UnauthorisedError, 'missing Authorization header' if header.nil?

        session_token = header.[](/Bearer (\S+)/, 1)

        raise UnauthorisedError, 'invalid Authorization header' if session_token.nil?

        rack_env['shopify-client.shop'] = DecodeSessionToken.new.(session_token)
      rescue DecodeSessionToken::Error
        raise UnauthorisedError, 'invalid session token'
      end
    end
  end
end
