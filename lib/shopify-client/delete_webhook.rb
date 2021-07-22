# frozen_string_literal: true

module ShopifyClient
  class DeleteWebhook
    # @param client [Client]
    # @param id [Integer]
    def call(client, id)
      client.delete("webhooks/#{id}")
    end
  end
end
