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

      ShopifyClient.webhooks.map do |topic, options|
        Thread.new do
          webhook = {}.tap do |webhook|
            webhook[:topic] = topic
            webhook[:fields] = options[:fields] unless options[:fields].empty?
          end

          create_webhook.(client, webhook)
        end
      end.map(&:value)
    end
  end
end
