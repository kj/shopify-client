# frozen_string_literal: true

require_relative '../lib/shopify-client'

$shop = ENV['TEST_SHOP']
$password = ENV['TEST_PASSWORD']

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expose_dsl_globally = false
  config.filter_gems_from_backtrace 'faraday'
  # config.order = :random # TODO: use order: :defined metadata for specific specs
end

ShopifyClient.configure do |config|
  config.api_key = 'test'
  config.logger = Logger.new($stdout) if ENV['VERBOSE']
  config.oauth_redirect_uri = 'test'
  config.oauth_scope = 'test'
  config.shared_secret = 'test'
  config.webhook_uri = 'test'
end
