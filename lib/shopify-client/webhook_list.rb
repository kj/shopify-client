# frozen_string_literal: true

module ShopifyClient
  class WebhookList
    def initialize
      @webhooks = {}
    end

    # Register a handler for a webhook topic. The callable handler should
    # receive a single {Webhook} argument.
    #
    # @param topic [String]
    # @param handler [#call]
    # @param fields [Array<String>] e.g. %w[id tags]
    def register(topic, handler = nil, fields: nil, &block)
      raise ArgumentError unless nil ^ handler ^ block

      handler = block if block

      self[topic][:handlers] << handler
      self[topic][:fields] |= fields # merge fields with previous fields

      nil
    end

    # Call each of the handlers registered for the given topic in turn.
    #
    # @param webhook [Webhook]
    def delegate(webhook)
      self[webhook.topic][:handlers].each do |handler|
        handler.(webhook)
      end
    end

    # @param topic [String]
    def [](topic)
      @webhooks[topic] ||= {
        handlers: [],
        fields: [],
      }
    end

    include Enumerable

    # @yield [Hash]
    def each(&block)
      @webhooks.each(&block)
    end
  end
end
