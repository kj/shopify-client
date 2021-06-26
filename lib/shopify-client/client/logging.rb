# frozen_string_literal: true

require 'json'
require 'securerandom'

module ShopifyClient
  class Client
    class Logging < Faraday::Middleware
      # @param env [Faraday::Env]
      def on_request(env)
        env[:uuid] = SecureRandom.uuid

        ShopifyClient.config.logger.info({
          source: 'shopify-client',
          type: 'request',
          info: {
            transaction_id: env[:uuid],
            method: env[:method].to_s,
            url: env[:url].to_s,
          },
        }.to_json)
      end

      # @param env [Faraday::Env]
      def on_complete(env)
        ShopifyClient.config.logger.info({
          source: 'shopify-client',
          type: 'response',
          info: {
            transaction_id: env[:uuid],
            status: env[:status],
            api_call_limit: env[:response_headers]['X-Shopify-Shop-Api-Call-Limit'],
          },
        }.to_json)
      end
    end
  end
end
