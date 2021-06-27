# frozen_string_literal: true

require 'jwt'

module ShopifyClient
  module Cookieless
    class DecodeSessionToken
      Error = Class.new(Error)

      # @param token [String]
      #
      # @return [String] the *.myshopify.com domain of the authenticated shop
      #
      # @raise [Error]
      def call(token)
        payload, _ = JWT.decode(token, ShopifyClient.config.shared_secret, true, algorithm: 'HS256')

        raise Error unless valid?(payload)

        parse_myshopify_domain(payload)
      rescue JWT::DecodeError
        raise Error
      end

      # @param payload [Hash]
      #
      # @return [String]
      private def parse_myshopify_domain(payload)
        payload['dest'].sub('https://', '')
      end

      # @param payload [Hash]
      #
      # @return [Boolean]
      private def valid?(payload)
        return false unless payload['aud'] == ShopifyClient.config.api_key
        return false unless payload['iss'].start_with?(payload['dest'])

        true
      end
    end
  end
end
