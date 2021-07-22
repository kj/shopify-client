# frozen_string_literal: true

module ShopifyClient
  class CreateWebhook
    # @param client [Client]
    # @param webhook [Hash]
    # @option webhook [String] :topic
    # @option webhook [Array<String>] :fields
    #
    # @return [Integer] ID
    def call(client, webhook)
      raise ConfigError, 'webhook_uri is not set' unless ShopifyClient.config.webhook_uri

      client.post('webhooks', webhook: webhook.merge(
        address: ShopifyClient.config.webhook_uri,
      )).data['webhook']['id']
    rescue Response::Error => e
      raise e unless e.response.errors.message?([
        /has already been taken/,
      ])
    end
  end
end
