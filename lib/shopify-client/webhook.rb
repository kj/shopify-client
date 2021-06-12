# frozen_string_literal: true

require 'json'

module ShopifyClient
  # @!attribute [rw] myshopify_domain
  #   @return [String]
  # @!attribute [rw] topic
  #   @return [String]
  # @!attribute [rw] raw_data
  #   @return [String]
  Webhook = Struct.new(:myshopify_domain, :topic, :raw_data) do
    # @return [Hash]
    def data
      @data ||= JSON.parse(raw_data)
    rescue JSON::ParserError
      {}
    end

    alias_method :to_h, :data

    # @return [String]
    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
