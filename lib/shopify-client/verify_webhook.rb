# frozen_string_literal: true

require 'base64'
require 'openssl'

module ShopifyClient
  class VerifyWebhook
    Error = Class.new(Error)

    # Verify that the webhook request originated from Shopify.
    #
    # @param data [String] the signed request data
    # @param hmac [String] the signature
    #
    # @raise [Error] if signature is invalid
    def call(data, hmac)
      digest = OpenSSL::Digest::SHA256.new
      digest = OpenSSL::HMAC.digest(digest, ShopifyClient.config.shared_secret, data)
      digest = Base64.encode64(digest).strip

      raise Error, 'invalid signature' unless digest == hmac
    end
  end
end
