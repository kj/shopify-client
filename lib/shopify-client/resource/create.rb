# frozen_string_literal: true

module ShopifyClient
  module Resource
    module Create
      # @param base [Class]
      def self.included(base)
        base.include(Base)
      end

      # @param client [Client]
      # @param data [Hash]
      #
      # @return [Integer] the new result.id
      def create(client, data)
        result = client.post(resource_name, resource_name_singular => data).data[resource_name_singular]

        result['id'].tap do |id|
          ShopifyClient.config.logger({
            source: 'shopify-client',
            type: 'create',
            info: {
              resource: resource_name,
              id: id,
            },
          }.to_json)
        end
      end
    end
  end
end
