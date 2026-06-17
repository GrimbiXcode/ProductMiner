# frozen_string_literal: true

require "bundler/setup"
require "rspec"
require "webmock/rspec"
require "json"
require "logger"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Print the 10 slowest examples and example groups at the
  # end of the spec run
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    # Stub logger to suppress output during tests
    @test_logger = Logger.new(File::NULL)
    allow(Logger).to receive(:new).and_return(@test_logger)
  end
end

# Stub Redis for Sidekiq in tests
require "sidekiq/testing"
Sidekiq::Testing.fake!

# Stub database connection for tests
module ProductMiner
  class Database
    attr_reader :db, :price_records

    def initialize(*_args)
      @db = MockDatabase.new
      @price_records = MockPriceRecord.new
    end

    def test_connection
      true
    end

    def close; end
  end

  class MockDatabase
    def tables
      []
    end

    def table_exists?(_table)
      false
    end

    def create_table(_name, &_block); end

    def disconnect; end
  end

  class MockPriceRecord
    def save(_record)
      true
    end

    def find_by_product_id(_product_id, limit: 100)
      []
    end

    def find_recent(miner: nil, hours: 24)
      []
    end

    def latest_price(_product_id)
      nil
    end
  end
end

# Load the library
require_relative "../lib/product_miner"
