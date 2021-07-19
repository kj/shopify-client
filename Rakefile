namespace :test do
  task :unit  do
    system 'bundle exec rspec -r./spec/spec_helper spec/unit'
  end

  task :integration do
    require 'dotenv'

    Dotenv.load

    missing_env = %w[
      TEST_SHOP
      TEST_PASSWORD
      TEST_WEBHOOK_URI
    ].select do |var|
      next if ENV[var]

      puts "Missing environment variable #{var}"

      true
    end

    exit 1 if missing_env.any?

    system 'bundle exec rspec -r./spec/spec_helper spec/integration -f documentation'
  end

  task default: :unit
end

task default: [
  'test:unit',
  'test:integration',
]
