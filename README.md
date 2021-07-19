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
4. [OAuth](#oauth)
5. [Cookieless authentication](#cookieless-authentication)
    * [Rack middleware](#rack-middleware)
    * [Manual check](#manual-check)
6. [Webhooks](#webhooks)
    * [Configure webhooks](#configure-webhooks)
    * [Create and delete webhooks](#create-and-delete-webhooks)
7. [Verification](#verification)
    * [Verify callbacks](#verify-callbacks)
    * [Verify webhooks](#verify-webhooks)
8. [Mixins](#mixins)
    * [Read a resource](#read-a-resource)
    * [Create a resource](#create-a-resource)
    * [Update a resource](#update-a-resource)
    * [Delete a resource](#delete-a-resource)
9. [Testing](#testing)
    * [Integration tests](#integration-tests)


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
      config.logger = Logger.new($stdout) # defaults to a null logger
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
    client.graphql(%(
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
    )).data['data']['orders']

Request logging is disabled by default. To enable it:

    ShopifyClient.config.logger = Logger.new($stdout)

Request throttling is enabled by default. If you're using Redis, throttling will
automatically make use of it; otherwise, throttling will only be maintained
across a single thread.


### Make bulk API requests

The gem wraps Shopify's bulk query API by writing the result to a temporary file
and yielding an enumerator which itself streams each line of the result to limit
memory usage.

    client.graphql_bulk(%(
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
    )) do |lines|
      db.transaction do
        lines.each do |product|
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
expires (the default TTL is 1 hour). If you're using Redis, it will be used as
the cache store; otherwise, the cache will be stored in a thread local variable.

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


OAuth
-----

Redirect unauthorised users through the Shopify OAuth flow:

    authorise = ShopifyClient::Authorise.new

    redirect_to authorise.authorisation_code_url(myshopify_domain)

Once the user returns to the app, exchange the authorisation code for an access
token:

    access_token = authorise.(client, authorisation_code)


Cookieless authentication
-------------------------

Embedded apps using App Bridge are required to use the cookieless authentication
system which uses JWT session tokens rather than cookies to authenticate users
signed into the Shopify admin.


### Rack middleware

In config.ru, or wherever you set up your middleware stack:

    use ShopifyClient::Cookieless::Middleware

You can also control when session tokens are checked with a predicate (such as
only for certain paths):

    use ShopifyClient::Cookieless::Middleware, is_authenticated: ->(env) do
      # ...
    end


### Manual check

You can also check the Authorization header manually, if you require more
control than the middleware provides:

    begin
      ShopifyClient::Cookieless::CheckHeader.new.(env)
    rescue ShopifyClient::Error => e
      # ...
    end


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


Mixins
------

A set of mixins is provided for easily creating repository classes for API
resources. Each mixin represents an operation or a set of operations, e.g.
reading and writing data to/from the API.


### Read a resource

    class OrderRepository
      include ShopifyClient::Resource::Read

      resource :orders

      default_params fields: 'id,tags', limit: 250
    end

    order_repo = OrderRepository.new

Find a single result:

    order_repo.find_by_id(client, id)

Iterate over results (automatic pagination):

    order_repo.all(client).each do |order|
      # ...
    end


### Create a resource

    class OrderRepository
      include ShopifyClient::Resource::Create

      resource :orders
    end

    order_repo = OrderRepository.new

    order_repo.create(client, new_order)


### Update a resource

    class OrderRepository
      include ShopifyClient::Resource::Update

      resource :orders
    end

    order_repo = OrderRepository.new

    order_repo.update(client, id, order)


### Delete a resource

    class OrderRepository
      include ShopifyClient::Resource::Delete

      resource :orders
    end

    order_repo = OrderRepository.new

    order_repo.delete(client, id)


Testing
-------

### Integration tests

The integration tests require a private app with the scope `write_products`.
Create a .env file specifying the test shop, private app password, and a valid
webhook URI:

    TEST_SHOP='test-shop.myshopify.com'
    TEST_PASSWORD='shppa_...'
    TEST_WEBHOOK_URI='https://.../webhooks'

Run the suite:

    $ bundle exec rake test:integration
