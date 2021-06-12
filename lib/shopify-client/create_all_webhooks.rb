# frozen_string_literal: true

module ShopifyClient
  class CreateAllWebhooks
    # Create all registered webhooks for a shop.
    #
    # @param client [Client]
    #
    # @return [Array<Hash>] response data
    def call(client)
      create_webhook = CreateWebhook.new

      ShopifyClient.webhooks.map do |topic|
        Thread.new do
          create_webhook.(client, {
            topic: topic,
            fields: topic[:fields],
          })
        end
      end.map(&:value)
    end
  end
end
