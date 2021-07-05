# frozen_string_literal: true

module ShopifyClient
  RSpec.describe 'Basic requests' do
    let(:client) { Client.new($shop, $password) }

    example_group 'reading' do
      example 'make a GET request' do
        response = client.get('shop', fields: 'id,domain')

        expect(response.status_code).to be(200)
        expect(response.data['shop'].keys).to contain_exactly('id', 'domain')
      end

      example 'make a GraphQL request' do
        response = client.graphql(%(
          {
            shop {
              myshopifyDomain
            }
          }
        ))

        expect(response.status_code).to be(200)
        expect(response.data['data']['shop']['myshopifyDomain']).to eq($shop)
      end
    end

    example_group 'writing', order: :defined do
      id = nil

      example 'Make a POST request' do
        response = client.post('products', product: {
          title: 'Test product',
        })

        id = response.data['product']['id']

        expect(response.status_code).to be(201)
        expect(id).to be_a(Integer)
      end

      example 'Make a PUT request' do
        skip if id.nil?

        response = client.put("products/#{id}", product: {
          id: id,
          title: 'Test product (updated)',
        })

        expect(response.status_code).to be(200)
      end

      example 'Make a DELETE request' do
        skip if id.nil?

        response = client.delete("products/#{id}")

        expect(response.status_code).to be(200)
      end
    end
  end
end
