# frozen_string_literal: true

module ShopifyClient
  module Resource
    module Update
      # @param base [Class]
      def self.included(base)
        base.include(Base)
      end

      # @param client [Client]
      # @param id [Integer]
      # @param data [Hash]
      def update(client, id, data)
        client.put("#{resource_name}/#{id}", resource_name_singular => data)

        ShopifyClient.config.logger({
          source: 'shopify-client',
          type: 'update',
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
