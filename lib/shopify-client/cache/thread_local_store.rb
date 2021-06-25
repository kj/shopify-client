# frozen_string_literal: true

module ShopifyClient
  module Cache
    class ThreadLocalStore < Store
      # @see Store#get
      def get(key)
        return nil if expired?(key)

        value = Thread.current[key]

        @decode.(value) unless value.nil?
      end

      # @see Store#set
      def set(key, value, ttl: ShopifyClient.config.cache_ttl)
        Thread.current[key] = @encode.(value)

        if ttl > 0
          Thread.current[build_expiry_key(key)] = Time.now + ttl
        end
      end

      # @see Store#clear
      def clear(key)
        Thread.current[key] = nil
        Thread.current[build_expiry_key(key)] = nil
      end

      # @param key [String]
      #
      # @return [Boolean]
      private def expired?(key)
        expires_at = Thread.current[build_expiry_key(key)]

        expires_at.nil? ? false : Time.now > expires_at
      end

      # @param key [String]
      #
      # @return [String]
      private def build_expiry_key(key)
        "#{key}:expires_at"
      end
    end
  end
end
