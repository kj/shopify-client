# frozen_string_literal: true

require 'openssl'

module ShopifyClient
  class VerifyRequest
    Error = Class.new(Error)

    # Verify that the request originated from Shopify.
    #
    # @param params [Hash] the request params
    #
    # @raise [Error] if signature is invalid
    def call(params)
      params = params.to_h.transform_keys(&:to_s)
      digest = OpenSSL::Digest::SHA256.new
      digest = OpenSSL::HMAC.hexdigest(digest, ShopifyClient.config.shared_secret, encoded_params(params))

      raise Error, 'invalid signature' unless digest == params['hmac']
    end

    # @param params [Hash]
    #
    # @return [String]
    private def encoded_params(params)
      params.reject do |k, _|
        k == 'hmac'
      end.map do |k, v|
        [].tap do |param|
          param << k.gsub(/./) { |c| encode_key(c) }
          param << '='
          param << v.gsub(/./) { |c| encode_val(c) }
        end.join
      end.join('&')
    end

    # @param chr [String]
    #
    # @return [String]
    private def encode_key(chr)
      {'%' => '%25', '&' => '%26', '=' => '%3D'}[chr] || chr
    end

    # @param chr [String]
    #
    # @return [String]
    private def encode_val(chr)
      {'%' => '%25', '&' => '%26'}[chr] || chr
    end
  end
end
