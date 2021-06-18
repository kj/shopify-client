# frozen_string_literal: true

module ShopifyClient
  class Authorise
    Error = Class.new(Error)

    # @param myshopify_domain [String]
    def authorisation_code_url(myshopify_domain)
      format('https://%s/admin/oauth/authorize?client_id=%s&scope=%s&redirect_uri=%s',
        myshopify_domain,
        ShopifyClient.config.api_key,
        ShopifyClient.config.scope,
        ShopifyClient.config.redirect_uri,
      ]
    end

    # Exchange an authorisation code for a new Shopify access token.
    #
    # @param client [Client]
    # @param authorisation_code [String]
    #
    # @return [String] the access token
    #
    # @raise [Error] if the response is invalid
    def call(client, authorisation_code)
      data = client.post('/admin/oauth/access_token', {
        client_id: ShopifyClient.config.api_key,
        client_secret: ShopifyClient.config.shared_secret,
        code: authorisation_code,
      }).data

      raise Error if data['access_token'].nil?
      raise Error if data['scope'] != ShopifyClient.config.scope

      data['access_token']
    end
  end
end
