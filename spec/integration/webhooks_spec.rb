# frozen_string_literal: true

module ShopifyClient
  RSpec.describe 'Webhooks', order: :defined do
    let(:client) { Client.new($shop, $password) }

    before do
      {
        create: %w[id handle],
        update: %w[id handle],
        delete: [],
      }.each do |topic, fields|
        ShopifyClient.webhooks.register("products/#{topic}", proc {}, fields: fields)
      end
    end

    example_group 'create' do
      subject(:create_all_webhooks) { CreateAllWebhooks.new }

      example 'all webhooks' do
        create_all_webhooks.(client)

        # TODO: Check result.
      end
    end

    example_group 'delete' do
      subject(:delete_all_webhooks) { DeleteAllWebhooks.new }

      example 'all webhooks' do
        delete_all_webhooks.(client)

        # TODO: Check result.
      end
    end
  end
end
