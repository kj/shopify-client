# frozen_string_literal: true

module ShopifyClient
  class Client
    class NormalisePath < Faraday::Middleware
      # @param env [Faraday::Env]
      def on_request(env)
        unless env[:url].path.end_with?('.json')
          env[:url].path += '.json'
        end
      end
    end
  end
end
