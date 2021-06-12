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
        ).tap(&:assert!)
      end
    end

    # @raise [ClientError] for status 4xx
    # @raise [ServerError] for status 5xx
    #
    # @see https://shopify.dev/concepts/about-apis/response-codes
    def assert!
      # TODO
    end

    # @return [String]
    def inspect
      "#<ShopifyClient::Response (#{status_code}, #{request.inspect})>"
    end
  end

  class Response
    # @!attribute [r] request
    #   @return [Request]
    # @!attribute [r] response
    #   @return [Response]
    class Error < Error
      # @param request [Request]
      # @param request [Response]
      def initialize(request, response)
        @request = request
        @response = response
      end

      attr_reader :request
      attr_reader :response

      # @return [String]
      def message
        if response.errors?
          "bad response (#{response.status_code}): #{response.error_messages.first}"
        else
          "bad response (#{response.status_code})"
        end
      end
    end

    # Client errors in the range 4xx.
    ClientError = Class.new(Error)
    # Server errors in the range 5xx.
    ServerError = Class.new(Error)
    # The access token was not accepted.
    InvalidAccessTokenError = Class.new(ClientError)
    # The shop is frozen/locked/unavailable.
    ShopError = Class.new(ClientError)

    # The GraphQL API always responds with a status code of 200.
    GraphQLClientError = Class.new(ClientError) do
      def message
        case
        when response.errors?
          "bad response: #{response.error_messages.first}"
        when response.user_errors?
          "bad response: #{response.user_error_messages.first}"
        else
          "bad response"
        end
      end
    end
  end
end
