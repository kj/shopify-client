require './lib/shopify-client'

require 'dotenv'

Dotenv.load

module Helpers
  def client
    ShopifyClient::Client.new(ENV['SHOPIFY_MYSHOPIFY_DOMAIN'], ENV['SHOPIFY_PASSWORD'])
  end
end

include Helpers
