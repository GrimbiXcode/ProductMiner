# frozen_string_literal: true

require "bundler/setup"
require "rspec"
require "webmock/rspec"
require "json"

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

  # Set test environment
  config.before(:suite) do
    ENV["RACK_ENV"] = "test"
  end
end

# Load Sidekiq testing
begin
  require "sidekiq/testing"
  Sidekiq::Testing.fake!
rescue LoadError
  # Sidekiq might not be loaded yet, that's okay
end
