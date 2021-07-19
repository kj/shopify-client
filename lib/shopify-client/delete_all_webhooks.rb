# frozen_string_literal: true

module ShopifyClient
  class DeleteAllWebhooks
    # Delete any existing webhooks.
    #
    # @param client [Client]
    #
    # @return [Array<Hash>] response data
    def call(client)
      webhooks = client.get('webhooks').data['webhooks']

      delete_webhook = DeleteWebhook.new

      webhooks.map do |webhook|
        Thread.new do
          delete_webhook.(client, webhook['id'])
        end
      end.map(&:value)
    end
  end
end
