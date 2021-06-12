# frozen_string_literal: true

module ShopifyClient
  module Throttling
    # @abstract
    class Strategy < Faraday::Middleware
      # @param env [Faraday::Env]
      def on_request(env)
        interval_key = build_interval_key(env)

        sleep(interval(interval_key))

        after_sleep(env, interval_key)
      end

      # @param env [Faraday::Env]
      #
      # @return [String]
      def build_interval_key(env)
        myshopify_domain = env.dig(:shopify, :myshopify_domain) || 'unknown'

        format('shopify-client:throttling:%s', myshopify_domain)
      end

      # Sleep interval in seconds.
      #
      # @param interval_key [String]
      #
      # @return [Numeric]
      def interval(interval_key)
        0
      end

      # Hook for setting the interval key.
      #
      # @param env [Faraday::Env]
      # @param interval_key [String]
      def after_sleep(env, interval_key)
        nil
      end

      # Time in milliseconds since the UNIX epoch.
      #
      # @return [Integer]
      def timestamp
        (Time.now.to_f * 1000).to_i
      end
    end
  end
end
