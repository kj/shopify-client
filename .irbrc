require './lib/shopify-client'

require 'dotenv'

Dotenv.load

module Helpers
  def client
    ShopifyClient::Client.new(ENV['TEST_SHOP'], ENV['TEST_PASSWORD'])
  end
end

include Helpers
