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
  Response = Struct.new(:request, :status_code, :headers, :data)

  # NOTE: Reopened for proper scoping of error classes.
  class Response
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
          faraday_response.body || {},
        ).tap(&:assert!)
      end
    end

    # @raise [ClientError] for status 4xx
    # @raise [ServerError] for status 5xx
    #
    # @see https://shopify.dev/concepts/about-apis/response-codes
    def assert!
      case status_code
      when 401
        if error_message?([/access token/i])
          raise InvalidAccessTokenError.new(request, self), 'Invalid access token'
        else
          raise ClientError.new(request, self)
        end
      when 402
        raise ShopError.new(request, self), 'Shop is frozen, awaiting payment'
      when 403
        # NOTE: Not sure what this one means (undocumented).
        if error_message?([/unavailable shop/i])
          raise ShopError.new(request, self), 'Shop is unavailable'
        else
          raise ClientError.new(request, self)
        end
      when 423
        raise ShopError.new(request, self), 'Shop is locked'
      when 400..499
        raise ClientError.new(request, self)
      when 500..599
        raise ServerError.new(request, self)
      end

      # GraphQL always has status 200.
      if request.graphql? && (errors? || user_errors?)
        raise GraphQLClientError.new(request, self)
      end
    end

    # @return [Hash]
    private def link
      @link ||= ParseLinkHeader.new.(headers['Link'])
    end

    # Request the next page for a GET request, if any.
    #
    # @param [Client]
    #
    # @return [Response, nil]
    def next_page(client)
      return nil unless link[:next]

      client.get(request.path, link[:next])
    end

    # Request the next page for a GET request, if any.
    #
    # @param [Client]
    #
    # @return [Response, nil]
    def previous_page(client)
      return nil unless link[:previous]

      client.get(request.path, link[:previous])
    end

    # Response errors (usually included with a 422 response).
    #
    # @return [ResponseErrors]
    def errors
      @errors ||= ResponseErrors.from_response_data(data)
    end

    # @return [Boolean]
    def errors?
      errors.any?
    end

    # GraphQL user errors (errors in mutation input).
    #
    # @return [ResponseUserErrors, nil]
    def user_errors
      return nil unless request.graphql?

      @user_errors ||= ResponseUserErrors.from_response_data(data)
    end

    # @return [Boolean]
    def user_errors?
      return false unless request.graphql?

      user_errors.any?
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
      # @param response [Response]
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

    # Client errors in the 4xx range.
    ClientError = Class.new(Error)
    # Server errors in the 5xx range.
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
