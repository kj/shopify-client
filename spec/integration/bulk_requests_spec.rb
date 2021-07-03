# frozen_string_literal: true

module ShopifyClient
  RSpec.describe 'Bulk requests' do
    example 'make a bulk request' do
      client = Client.new($shop, $password)

      client.graphql_bulk(%(
        {
          products {
            edges {
              node {
                id
                handle
              }
            }
          }
        }
      )) do |lines|
        expect(lines).to be_a(Enumerator)

        lines.each do |product|
          expect(product.keys).to contain_exactly('id', 'handle')
        end
      end
    end
  end
end
