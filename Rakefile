task :test_integration do
  require 'dotenv'

  Dotenv.load

  missing_env = %w[
    SHOPIFY_MYSHOPIFY_DOMAIN
    SHOPIFY_PASSWORD
  ].select do |var|
    next if ENV[var]

    puts "Missing environment variable #{var}"

    true
  end

  exit 1 if missing_env.any?

  system 'bundle exec rspec -r./spec/spec_helper spec/integration/shopify-client -f documentation'
end

task :test do
  system 'bundle exec rspec -r./spec/spec_helper spec/unit'
end

task default: :test
