# frozen_string_literal: true

module ShopifyClient
  # @!attribute [rw] myshopify_domain
  #   @return [String]
  # @!attribute [rw] access_token
  #   @return [String, nil]
  # @!attribute [rw] method
  #   @return [Symbol]
  # @!attribute [rw] path
  #   @return [String]
  # @!attribute [rw] params
  #   @return [Hash]
  # @!attribute [rw] headers
  #   @return [Hash]
  # @!attribute [rw] data
  #   @return [Hash, nil]
  Request = Struct.new(
    :myshopify_domain,
    :access_token,
    :method,
    :uri,
    :params,
    :headers,
    :data
  )
end
