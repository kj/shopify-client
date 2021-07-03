# frozen_string_literal: true

module ShopifyClient
  RSpec.describe 'Basic requests' do
    example 'make a GET request' do
      client = Client.new($shop, $password)

      response = client.get('shop', fields: 'id,domain')

      expect(response).to be_a(Response)
      expect(response.status_code).to be(200)
      expect(response.data['shop'].keys).to contain_exactly('id', 'domain')
    end

    example 'make a GraphQL request' do
      client = Client.new($shop, $password)

      response = client.graphql(%(
        {
          shop {
            myshopifyDomain
          }
        }
      ))

      expect(response).to be_a(Response)
      expect(response.status_code).to be(200)
      expect(response.data['data']['shop']['myshopifyDomain']).to eq($shop)
    end
  end
end
