# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

module ShopifyClient
  # @!attribute [r] myshopify_domain
  #   @return [String]
  # @!attribute [r] access_token
  #   @return [String]
  class Client
    # @param myshopify_domain [String]
    # @param access_token [String, nil] if request is authenticated
    def initialize(myshopify_domain, access_token = nil)
      @conn = Faraday.new(
        headers: {
          'X-Shopify-Access-Token' => access_token,
        },
        url: "https://#{myshopify_domain}/admin/api/#{ShopifyClient.config.api_version}",
      ) do |conn|
        # Request throttling to avoid API rate limit.
        conn.use default_throttling_strategy
        # Retry for 429, too many requests.
        conn.use Faraday::Request::Retry, {
          backoff_factor: 2,
          interval: 0.5,
          retry_statuses: [429],
        }
        # Retry for 5xx, server errors.
        conn.use Faraday::Request::Retry, {
          exceptions: [
            Faraday::ConnectionFailed,
            Faraday::RetriableResponse,
            Faraday::ServerError,
            Faraday::SSLError,
            Faraday::TimeoutError,
          ],
          backoff_factor: 2,
          interval: 0.5,
          retry_statuses: (500..599).to_a,
        }
        conn.use FaradayMiddleware::EncodeJson
        conn.use FaradayMiddleware::ParseJson, content_type: 'application/json'
        # Add .json suffix if not present (all endpoints use this).
        conn.use NormalisePath
        conn.use Logging
      end

      @myshopify_domain = myshopify_domain
      @access_token = access_token
    end

    # @return [Throttling::Strategy]
    def default_throttling_strategy
      if defined?(Redis)
        Throttling::RedisStrategy
      else
        Throttling::ThreadLocalStrategy
      end
    end

    attr_reader :myshopify_domain
    attr_reader :access_token

    # @see Faraday::Connection#delete
    #
    # @return [Response]
    def delete(...)
      Response.from_faraday_response(@conn.delete(...), self)
    end

    # @see Faraday::Connection#get
    #
    # @return [Response]
    def get(...)
      Response.from_faraday_response(@conn.get(...), self)
    end

    # @see CachedRequest#initialize
    def get_cached(...)
      CachedRequest.new(...).(self)
    end

    # @see Faraday::Connection#post
    #
    # @return [Response]
    def post(...)
      Response.from_faraday_response(@conn.post(...), self)
    end

    # @see Faraday::Connection#put
    #
    # @return [Response]
    def put(...)
      Response.from_faraday_response(@conn.put(...), self)
    end

    # @param query [String] the GraphQL query
    # @param variables [Hash] the GraphQL variables (if any)
    #
    # @return [Response]
    def graphql(query, variables = {})
      Response.from_faraday_response(@conn.post('graphql', {
        query: query,
        variables: variables,
      }), self)
    end

    # If called with a block, calls {BulkRequest::Operation#call} immediately,
    # else, returns the {BulkRequest::Operation}.
    #
    # @param query [String] the GraphQL query
    #
    # @return [Operation]
    def graphql_bulk(query, &block)
      op = BulkRequest.new.(self, query)

      block ? op.(&block) : op
    end

    # @return [String]
    def inspect
      "#<ShopifyClient::Client (#{@myshopify_domain})>"
    end
  end
end
