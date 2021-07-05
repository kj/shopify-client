# frozen_string_literal: true

module ShopifyClient
  RSpec.describe 'Throttling' do
    # TODO
    #
    # Test that many quick requests in succession are throttled, and do not
    # trigger a 429 response. This could be tricky due to the 429 retry
    # middleware, and I'm not really keen on making that configurable just for
    # testing purposes.
  end
end
