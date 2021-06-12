# frozen_string_literal: true

module ShopifyClient
  class DeleteWebhook
    # @param client [Client]
    # @param id [Integer]
    #
    # @return [Hash] response data
    def call(client, id)
      client.delete(credentials, "webhooks/#{id}")
    end
  end
end
