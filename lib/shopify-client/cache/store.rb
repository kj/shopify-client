# frozen_string_literal: true

require 'json'

module ShopifyClient
  module Cache
    # @abstract
    class Store
      # @param encode [#call]
      # @param decode [#call]
      #
      # @example
      #   store = Store.new(
      #     encode: MessagePack.method(:pack),
      #     decode: MessagePack.method(:unpack),
      #   )
      def initialize(encode: JSON.method(:generate), decode: JSON.method(:parse))
        @encode = encode
        @decode = decode
      end

      # Fetch a value from the cache, falling back to the result of the given
      # block when the cache is empty/expired.
      #
      # @param key [String]
      # @param ttl [Integer] in seconds
      #
      # @return [Object]
      def call(key, ttl: ShopifyClient.config.cache_ttl, &block)
        if expired?(key, ttl)
          value = get(key)
        else
          value = nil
        end

        if value.nil?
          value = block.()

          set(key, value, ttl: ttl)
        end

        value
      end

      # Override for custom expiry check, otherwise always false. For example,
      # Redis checks key expiry automatically, so a separate check is redundant.
      #
      # @param key [String]
      # @param ttl [Integer] in seconds
      #
      # @return [Boolean]
      private def expired?(key, ttl)
        false
      end

      # Get cached data, or nil if unset.
      #
      # @param key [String]
      #
      # @return [Object]
      private def get(key)
        raise NotImplementedError
      end

      # Overwrite cached data and set TTL (if implemented by child class).
      #
      # @param key [String]
      # @param value [Object]
      # @param ttl [Integer] in seconds
      def set(key, value, ttl: ShopifyClient.config.cache_ttl)
        raise NotImplementedError
      end

      # Clear cached data.
      #
      # @param key [String]
      def clear(key)
        raise NotImplementedError
      end
    end
  end
end
