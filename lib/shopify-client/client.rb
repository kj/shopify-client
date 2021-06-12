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
        if defined?(Redis)
          conn.use Throttling::RedisStrategy
        else
          conn.use Throttling::ThreadLocalStrategy
        end
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
        # Add .json suffix if not present (all endpoints use this).
        conn.use(Class.new(Faraday::Middleware) do
          def on_request(env)
            unless env[:url].path.end_with?('.json')
              env[:url].path += '.json'
            end
          end
        end)
        conn.use FaradayMiddleware::EncodeJson
        conn.use FaradayMiddleware::ParseJson, content_type: 'application/json'
      end

      @myshopify_domain = myshopify_domain
    end

    attr_reader :myshopify_domain
    attr_reader :access_token

    # @see Faraday::Connection#delete
    #
    # @return [Response]
    def delete(...)
      Response.from_faraday_response(@conn.delete(...))
    end

    # @see Faraday::Connection#get
    #
    # @return [Response]
    def get(...)
      Response.from_faraday_response(@conn.get(...))
    end

    # @see Faraday::Connection#post
    #
    # @return [Response]
    def post(...)
      Response.from_faraday_response(@conn.post(...))
    end

    # @see Faraday::Connection#put
    #
    # @return [Response]
    def put(...)
      Response.from_faraday_response(@conn.put(...))
    end

    # @param query [String] the GraphQL query
    # @param variables [Hash] the GraphQL variables (if any)
    #
    # @return [Response]
    def graphql(query, variables = {})
      Response.from_faraday_response(@conn.post('graphql', {
        query: query,
        variables: variables,
      }))
    end

    # @return [String]
    def inspect
      "#<ShopifyClient::Client (#{@myshopify_domain})>"
    end
  end
end
