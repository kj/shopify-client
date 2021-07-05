# frozen_string_literal: true

module ShopifyClient
  RSpec.describe 'Cached requests' do
    example_group 'make a cached GET request' do
      subject(:get_shop) do
        CachedRequest.new('shop', params: {fields: 'id,domain'})
      end

      before do
        get_shop.clear($shop)
      end

      example 'with Client' do
        client = Client.new($shop, $password)

        time1 = Time.now
        data1 = client.get_cached('shop', params: {fields: 'id,domain'})
        time2 = Time.now

        expect(data1['shop'].keys).to contain_exactly('id', 'domain')
        expect(time2 - time1).to be > 0.1

        time3 = Time.now
        data2 = client.get_cached('shop', params: {fields: 'id,domain'})
        time4 = Time.now

        expect(data2['shop'].keys).to contain_exactly('id', 'domain')
        expect(time4 - time3).to be < 0.005
      end

      example 'with CachedRequest' do
        client = Client.new($shop, $password)

        time1 = Time.now
        data1 = get_shop.(client)
        time2 = Time.now

        expect(data1['shop'].keys).to contain_exactly('id', 'domain')
        expect(time2 - time1).to be > 0.1

        time3 = Time.now
        data2 = get_shop.(client)
        time4 = Time.now

        expect(data2['shop'].keys).to contain_exactly('id', 'domain')
        expect(time4 - time3).to be < 0.005

        get_shop.clear($shop)

        time5 = Time.now
        data3 = get_shop.(client)
        time6 = Time.now

        expect(data3['shop'].keys).to contain_exactly('id', 'domain')
        expect(time6 - time5).to be > 0.1

        get_shop.set($shop, 'override')

        data4 = get_shop.(client)

        expect(data4).to eq('override')
      end
    end
  end
end
