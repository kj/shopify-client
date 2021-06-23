# frozen_string_literal: true

module ShopifyClient
  module Cache
    class ThreadLocalStore < Store
      # TODO

      # @param key [String]
      #
      # @return [String]
      private def build_expiry_key(key)
        "#{key}:expires_at"
      end
    end
  end
end
