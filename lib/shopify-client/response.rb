# frozen_string_literal: true

require 'addressable'

module ShopifyClient
  # @!attribute [rw] request
  #   @return [Request]
  # @!attribute [rw] status_code
  #   @return [Integer]
  # @!attribute [rw] headers
  #   @return [Hash]
  # @!attribute [rw] data
  #   @return [Hash]
  Response = Struct.new(:request, :status_code, :headers, :data) do
    class << self
      # @param faraday_response [Faraday::Response]
      #
      # @return [Response]
      def from_faraday_response(faraday_response)
        uri = Addressable::URI.parse(faraday_response.env[:url])

        new(
          Request.new(
            # Merchant myshopify.domain.
            uri.host,
            # Merchant access token.
            faraday_response.env[:request_headers]['X-Shopify-Access-Token'],
            # Request HTTP method.
            faraday_response.env[:method],
            # Request path.
            uri.path,
            # Request params.
            uri.query_values,
            # Request headers.
            faraday_response.env[:request_headers],
            # Request data.
            faraday_response.env[:request_body],
          ),
          faraday_response.status,
          faraday_response.headers,
          faraday_response.body,
        )
      end
    end
  end
end
