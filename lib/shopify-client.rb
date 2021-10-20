# frozen_string_literal: true

require 'dry-configurable'
require 'logger'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.tag = File.basename(__FILE__, '.rb')
loader.inflector.inflect(
  'shopify-client' => 'ShopifyClient',
  'version' => 'VERSION',
)
loader.setup

module ShopifyClient
  extend Dry::Configurable

  setting :api_key
  setting :api_version, default: '2021-04'
  setting :cache_ttl, default: 3600
  setting :logger, default: Logger.new(File::NULL).freeze
  setting :oauth_redirect_uri
  setting :oauth_scope
  setting :shared_secret
  setting :webhook_uri

  class << self
    # @param version [String]
    #
    # @raise [RuntimeError]
    def assert_api_version!(version)
      raise "requires API version >= #{version}" if config.api_version < version
    end

    # @return [WebhookList]
    #
    # @example Register webhook handlers
    #   ShopifyClient.webhooks.register('orders/create', OrdersCreateWebhook.new, fields: %w[id tags])
    #
    # @example Call handlers for a topic
    #   webhook = Webhook.new(myshopify_domain, topic, data)
    #
    #   ShopifyClient.webhooks.delegate(webhook)
    def webhooks
      @webhooks ||= WebhookList.new
    end
  end
end
