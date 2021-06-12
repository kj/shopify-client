# frozen_string_literal: true

module ShopifyClient
  module Throttling
    # Use Redis to maintain API call limit throttling across threads/processes.
    #
    # No delay for requests up to half of the call limit.
    class RedisStrategy < Strategy
      # @see Strategy#interval
      def interval(interval_key)
        num_requests, max_requests, header_timestamp = Redis.current.hmget(interval_key,
          :num_requests,
          :max_requests,
          :header_timestamp,
        ).map(&:to_i)

        num_requests = leak(num_requests, header_timestamp)

        max_unthrottled_requests = max_requests / 2

        if num_requests > num_unthrottled_requests
          Rational((num_requests - num_unthrottled_requests) * leak_rate, 1000)
        else
          0
        end
      end

      # @see Strategy#after_sleep
      def after_sleep(env, interval_key)
        header = env[:response_headers]['X-Shopify-Shop-Api-Call-Limit']

        return if header.nil?

        num_requests, max_requests = header.split('/')

        Redis.current.mapped_hmset(interval_key,
          num_requests: num_requests,
          max_requests: max_requests,
          header_timestamp: header_timestamp,
        )
      end

      # Find the actual number of requests by subtracting requests leaked by the
      # leaky bucket algorithm since the last header timestamp.
      #
      # @param num_requests [Integer]
      # @param header_timestamp [Integer]
      #
      # @return [Integer]
      def leak(num_requests, header_timestamp)
        n = Rational(timestamp - header_timestamp, leak_rate).floor

        n > num_requests ? 0 : num_requests - n
      end

      # Leak rate of the leaky bucket algorithm in milliseconds.
      def leak_rate
        500
      end
    end
  end
end
