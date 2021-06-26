# frozen_string_literal: true

module ShopifyClient
  module Resource
    module Delete
      # @param base [Class]
      def self.included(base)
        base.include(Base)
      end

      # @param client [Client]
      # @param id [Integer]
      def delete(client, id)
        client.delete("#{resource_name}/#{id}")

        ShopifyClient.config.logger({
          source: 'shopify-client',
          type: 'delete',
          info: {
            resource: resource_name,
            id: id,
          },
        }.to_json)

        nil
      end
    end
  end
end
