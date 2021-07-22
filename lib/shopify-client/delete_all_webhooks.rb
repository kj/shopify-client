# frozen_string_literal: true

module ShopifyClient
  class DeleteAllWebhooks
    # Delete any existing webhooks.
    #
    # @param client [Client]
    # @param ids [Array<Integer>, nil] GraphQL IDs
    def call(client, ids: nil)
      ids ||= client.graphql(%({
        webhookSubscriptions(first: 50) {
          edges {
            node {
              id
            }
          }
        }
      })).data['data']['webhookSubscriptions']['edges'].map do |edge|
        edge['node']['id']
      end

      return if ids.empty?

      client.graphql(%(
        mutation webhookSubscriptionDelete(
          #{ids.each_with_index.map { |_, i| %(
            $id#{i}: ID!
          )}.join("\n")}
        ) {
          #{ids.each_with_index.map { |_, i| %(
            webhookSubscriptionDelete#{i}: webhookSubscriptionDelete(id: $id#{i}) {
              userErrors {
                field
                message
              }
            }
          )}.join("\n")}
        }
      ), ids.each_with_index.each_with_object({}) do |(id, i), variables|
        variables["id#{i}"] = id
      end)
    end
  end
end
