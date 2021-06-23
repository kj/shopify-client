# frozen_string_literal: true

require 'digest'

module ShopifyClient
  # Caching for GET requests.
  #
  # @example
  #   get_shop = CachedRequest.new('shop', fields: 'domain,plan')
  #   get_shop.(client) # not cached, makes API request
  #   get_shop.(client) # cached
  class CachedRequest
    # @param request_path [String]
    # @param request_params [Hash]
    # @param store [Cache::Store]
    def initialize(request_path, request_params = {}, store: default_store)
      @request_path = request_path
      @request_params = request_params
      @store = store
    end

    # @return [Cache::Store]
    def default_store
      if defined?(Redis)
        Cache::RedisStore.new
      else
        Cache::ThreadLocalStore.new
      end
    end

    # @param client [Client]
    #
    # @return [Hash] response data
    def call(client)
      @store.(build_key(client.myshopify_domain)) do
        client.get(@request_path, @request_params).data
      end
    end

    # @param myshopify_domain [String]
    #
    # @return [String]
    private def build_key(myshopify_domain)
      separator = "\x1f" # ASCII unit separator

      format('shopify-client:cached_request:%s', Digest::SHA256.hexdigest([
        myshopify_domain,
        @request_path,
        @request_params.sort,
      ].join(separator)))
    end

    # Overwrite cached data for a given shop. This might be used when the data
    # is received from a webhook.
    #
    # @param myshopify_domain [String]
    # @param data [Hash]
    def set(myshopify_domain, data)
      @store.set(build_key(myshopify_domain), data)
    end

    # Clear the cached data for a given shop.
    #
    # @param myshopify_domain [String]
    def clear(myshopify_domain)
      @store.clear(build_key(myshopify_domain))
    end
  end
end
