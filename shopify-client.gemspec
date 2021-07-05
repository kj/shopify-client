$LOAD_PATH.unshift "#{__dir__}/lib"

require 'shopify-client/version'

Gem::Specification.new do |s|
  s.add_development_dependency 'dotenv', '~> 2.7'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_runtime_dependency 'addressable', '~> 2.7'
  s.add_runtime_dependency 'dry-configurable', '~> 0.12'
  s.add_runtime_dependency 'faraday', '~> 1.4'
  s.add_runtime_dependency 'faraday_middleware', '~> 1.0' # JSON middleware
  s.add_runtime_dependency 'jwt', '~> 2.2'
  s.add_runtime_dependency 'zeitwerk', '~> 2.4'
  s.author = 'Kelsey Judson'
  s.email = 'kelsey@kelseyjudson.dev'
  s.files = Dir.glob('lib/**/*') + %w[README.md]
  s.homepage = 'https://github.com/kj/shopify-client'
  s.license = 'ISC'
  s.name = 'shopify-client'
  s.summary = 'Shopify client library'
  s.version = ShopifyClient::VERSION
end
