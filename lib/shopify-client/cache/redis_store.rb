# frozen_string_literal: true

module ShopifyClient
  module Cache
    class RedisStore < Store
      # @see Store#get
      def get(key)
        value = Redis.current.get(key)

        @decode.(value) unless value.nil?
      end

      # @see Store#set
      def set(key, value, ttl: ShopifyClient.config.cache_ttl)
        Redis.current.set(key, @encode.(value))

        if ttl > 0
          Redis.current.expire(key, ttl)
        end
      end

      # @see Store#clear
      def clear(key)
        Redis.current.del(key)
      end
    end
  end
end
