shopify-client
==============

1. [Installation](#installation)
2. [Setup](#setup)
    * [Configuration](#configuration)
3. [Calling the API](#calling-the-api)
    * [Make API requests](#make-api-requests)
    * [Make bulk API requests](#make-bulk-api-requests)
    * [Make cached API requests](#make-cached-api-requests)
    * [Pagination](#pagination)
4. [Authorisation](#authorisation)
5. [Webhooks](#webhooks)
    * [Configure webhooks](#configure-webhooks)
    * [Create and delete webhooks](#create-and-delete-webhooks)
6. [Verification](#verification)
    * [Verify callbacks](#verify-callbacks)
    * [Verify webhooks](#verify-webhooks)


Installation
------------

Add the gem to your 'Gemfile':

    gem 'shopify-client'


Setup
-----

### Configuration

    ShopifyClient.configure do |config|
      config.api_key = '...'
      config.api_version = '...' # e.g. '2021-04'
      config.cache_ttl = 3600
      config.redirect_uri = '...' # for OAuth
      config.logger = Logger.new(STDOUT) # defaults to a null logger
      config.scope = '...'
      config.shared_secret = '...'
      config.webhook_uri = '...'
    end

All settings are optional and in some private apps, you may not require any
configuration at all.


Calling the API
---------------

### Make API requests

    client = ShopifyClient::Client.new(myshopify_domain, access_token)

    client.get('orders', since_id: since_id).data['orders']
    client.post('orders', order: new_order)
    client.graphql(<<~QUERY).data['data']['orders']
      {
        orders(first: 10) {
          edges {
            node {
              id
              tags
            }
          }
        }
      }
    QUERY

Request logging is disabled by default. To enable it:

    ShopifyClient.config.logger = Logger.new(STDOUT)

Request throttling is enabled by default. If you're using Redis, throttling will
automatically make use of it; otherwise, throttling will only be maintained
across a single thread.


### Make bulk API requests

The gem wraps Shopify's bulk query API by writing the result to a temporary file
and yielding each line of the result to limit memory usage.

    client.grahql_bulk(<<~QUERY) do |products|
      {
        products {
          edges {
            node {
              id
              handle
            }
          }
        }
      }
    QUERY
      db.transaction do
        products.each do |product|
          db[:products].insert(
            id: product['id'],
            handle: product['handle'],
          )
        end
      end
    end

Bulk requests are limited to one per shop at any one time. Creating a new bulk
request via the gem will cancel any request in progress for the shop.


### Make cached API requests

Make a cached GET request:

    client.get_cached('orders', params: {since_id: since_id})

Note that unlike `#get`, `#get_cached` returns the `Response#data` hash rather
than a `Response` object.

Making the same call with the same shop/client, will result in the data being
returned straight from the cache on subsequent calls, until the configured TTL
expires. If you're using Redis, it will be used as the cache store; otherwise,
the cache will be stored in a thread local variable.

You can also manually build and clear a cached request. For example, you might
need to clear the cache without waiting for the TTL if you receive an update
webhook indicating that the cached data is obsolete:

    get_shop = ShopifyClient::CachedRequest.new('shop')

    # Request shop data (from API).
    get_shop.(client)
    # Request shop data (from cache).
    get_shop.(client)

Clear the cache data to force fetch from API on next access:

    get_shop.clear(myshopify_domain)

Set the cache data (e.g. from shop/update webhook body):

    get_shop.set(myshopify_domain, new_shop)


### Pagination

When you make a GET request, you can request the next or the previous page
directly from the response object.

    page_1 = client.get('orders')
    page_2 = page_1.next_page
    page_1 = page_2.previous_page

When no page is available, `nil` will be returned.


Authorisation
-------------

Redirect unauthorised users through the Shopify OAuth flow:

    authorise = ShopifyClient::Authorise.new

    redirect_to authorise.authorisation_code_url(myshopify_domain)

Once the user returns to the app, exchange the authorisation code for an access
token:

    access_token = authorise.(client, authorisation_code)


Webhooks
--------

### Configure webhooks

Configure each webhook the app will create (if any), and register handlers:

    ShopifyClient.webhooks.register('orders/create', OrdersCreateWebhook.new, fields: %w[id tags])

You can register as many handlers as you need for a topic, and the gem will
merge required fields across all handlers when creating the webhooks.

To call/delegate a webhook to its handler for processing, you will likely want
to create a worker around something like this:

    webhook = ShopifyClient::Webhook.new(myshopify_domain, topic, data)

    ShopifyClient.webhooks.delegate(webhook)


### Create and delete webhooks

Create/delete all configured webhooks (see above):

    ShopifyClient::CreateAllWebhooks.new.(client)
    ShopifyClient::DeleteAllWebhooks.new.(client)

Create/delete webhooks manually:

    webhook = {topic: 'orders/create', fields: %w[id tags]}

    ShopifyClient::CreateWebhook.new.(client, webhook)
    ShopifyClient::DeleteWebhook.new.(client, webhook_id)


Verification
------------

### Verify requests

Verify callback requests with the request params:

    begin
      ShopifyClient::VerifyRequest.new.(params)
    rescue ShopifyClient::Error => e
      # ...
    end


### Verify webhooks

Verify webhook requests with the request data and the HMAC header:

    begin
      ShopifyClient::VerifyWebhook.new.(data, hmac)
    rescue ShopifyClient::Error => e
      # ...
    end
