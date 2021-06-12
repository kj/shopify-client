# frozen_string_literal: true

module ShopifyClient
  # Subclass this class for all gem exceptions, so that callers may rescue
  # any subclass with:
  #
  #     rescue ShopifyClient::Error => e
  Error = Class.new(StandardError)
end
