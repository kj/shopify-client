# frozen_string_literal: true

module ShopifyClient
  class CreateWebhook
    # @param client [Client]
    # @param webhook [Hash]
    # @option webhook [String] :topic
    # @option webhook [Array<String>] :fields
    #
    # @return [Hash] response data
    def call(client, webhook)
      client.post('webhooks', webhook: webhook.merge(
        address: ShopifyClient.config.webhook_uri,
      ))
    rescue Response::Error => e
      raise e unless e.response.errors.message?([
        /has already been taken/,
      ])
    end
  end
end
