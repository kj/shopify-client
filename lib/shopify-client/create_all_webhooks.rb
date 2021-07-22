# frozen_string_literal: true

module ShopifyClient
  class CreateAllWebhooks
    # Create all registered webhooks for a shop.
    #
    # @param client [Client]
    #
    # @return [Array<String>] GraphQL IDs
    def call(client)
      raise ConfigError, 'webhook_uri is not set' unless ShopifyClient.config.webhook_uri

      webhooks_with_index = ShopifyClient.webhooks.each_with_index

      return [] unless webhooks_with_index.any?

      client.graphql(%(
        mutation webhookSubscriptionCreate(
          #{webhooks_with_index.map { |_, i| %(
            $topic#{i}: WebhookSubscriptionTopic!
            $webhookSubscription#{i}: WebhookSubscriptionInput!
          )}.join("\n")}
        ) {
          #{webhooks_with_index.map { |_, i| %(
            webhookSubscriptionCreate#{i}: webhookSubscriptionCreate(
              topic: $topic#{i}
              webhookSubscription: $webhookSubscription#{i}
            ) {
              userErrors {
                field
                message
              }
              webhookSubscription {
                id
              }
            }
          )}.join("\n")}
        }
      ), webhooks_with_index.each_with_object({}) do |((topic, options), i), variables|
        variables["topic#{i}"] = topic_to_graphql(topic)
        variables["webhookSubscription#{i}"] = {}.tap do |subscription|
          subscription['callbackUrl'] = ShopifyClient.config.webhook_uri
          subscription['includeFields'] = options[:fields] unless options[:fields].empty?
        end
      end).data['data'].map do |_, mutation|
        mutation['webhookSubscription']['id']
      end
    end

    # @param topic [String]
    #
    # @return [String]
    private def topic_to_graphql(topic)
      topic.upcase.sub('/', '_')
    end
  end
end
