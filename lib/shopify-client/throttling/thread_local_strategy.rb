# frozen_string_literal: true

module ShopifyClient
  module Throttling
    # Maintain API call limit throttling across a single thread.
    class ThreadLocalStrategy < Strategy
      # @see Strategy#interval
      def interval(interval_key)
        return 0 if Thread.current[interval_key].nil?

        ms = (timestamp - Thread.current[interval_key])

        ms < minimum_interval ? Rational(minimum_interval - ms, 1000) : 0
      end

      # @see Strategy#after_sleep
      def after_sleep(env, interval_key)
        Thread.current[interval_key] = timestamp
      end

      # Minimum time between requests in milliseconds.
      #
      # @return [Integer]
      def minimum_interval
        500
      end
    end
  end
end
