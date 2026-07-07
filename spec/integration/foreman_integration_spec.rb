# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/product_miner/foreman/foreman"
require_relative "../../lib/product_miner/config"
require_relative "../../lib/product_miner/database"
require_relative "../support/database_helpers"

RSpec.describe "Foreman Integration", type: :integration do
  let(:test_config) do
    {
      "redis" => { "host" => "localhost", "port" => 6379, "db" => 1 },
      "database" => { "adapter" => "sqlite", "database" => ":memory:" },
      "products" => [
        { "id" => "204451300000", "name" => "Test Product", "miner" => "migros", "enabled" => true }
      ],
      "scheduler" => {
        "migros" => { "cron" => "* * * * *", "enabled" => true }
      }
    }
  end

  let(:config) do
    # Create a simple config object
    SimpleConfig.new(test_config)
  end

  let(:foreman) { Foreman.new(config) }

  # Simple config class for testing
  class SimpleConfig
    def initialize(data)
      @data = data
    end

    def redis_config
      @data["redis"]
    end

    def database_config
      @data["database"]
    end

    def products
      @data["products"]
    end

    def enabled_products
      products.select { |p| p["enabled"] != false }
    end

    def scheduler_config
      @data["scheduler"]
    end

    def miner_config(miner_name)
      @data.dig("miners", miner_name) || {}
    end

    def logging_config
      @data["logging"] || { level: "info" }
    end

    def [](key)
      @data[key]
    end

    def dig(*keys)
      @data.dig(*keys)
    end
  end

  describe "end-to-end workflow" do
    let(:product_id) { "204451300000" }
    let(:mock_product_data) do
      {
        "id" => product_id,
        "name" => "Test Product",
        "price" => { "value" => 10.99, "currency" => "CHF" },
        "originalPrice" => { "value" => 12.99 }
      }
    end

    before do
      # Mock the MigrosApi
      allow(MigrosApi).to receive(:new).and_return(double("MigrosApi", read_product_details: mock_product_data))
      
      # Mock Sidekiq
      allow(Sidekiq::Testing).to receive(:fake!).and_return(nil)
      allow(foreman).to receive(:setup_redis).and_return(nil)
    end

    it "successfully processes a product from start to finish" do
      # Mock database setup
      mock_db = double("Database")
      mock_price_records = double("PriceRecords")
      
      allow(mock_db).to receive(:price_records).and_return(mock_price_records)
      allow(mock_price_records).to receive(:save).and_return(true)
      allow(foreman).to receive(:setup_database).and_return(mock_db)
      
      # This should not raise any errors
      expect { foreman.perform("migros", product_id) }.not_to raise_error
    end

    it "extracts correct data from product response" do
      mock_db = double("Database")
      mock_price_records = double("PriceRecords")
      
      allow(mock_db).to receive(:price_records).and_return(mock_price_records)
      allow(mock_price_records).to receive(:save) do |record|
        expect(record[:product_id]).to eq(product_id)
        expect(record[:product_name]).to eq("Test Product")
        expect(record[:miner]).to eq("migros")
        expect(record[:price]).to eq(10.99)
        expect(record[:original_price]).to eq(12.99)
        expect(record[:currency]).to eq("CHF")
        expect(record[:product_data]).to eq(mock_product_data.to_json)
        expect(record[:recorded_at]).to be_a(Time)
        true
      end
      
      allow(foreman).to receive(:setup_database).and_return(mock_db)
      
      foreman.perform("migros", product_id)
    end
  end

  describe "job installation workflow" do
    before do
      allow(Sidekiq::Testing).to receive(:fake!).and_return(nil)
      allow(foreman).to receive(:setup_redis).and_return(nil)
      allow(Sidekiq::Cron::Job).to receive(:destroy_all!).and_return(nil)
      allow(Sidekiq::Cron::Job).to receive(:create).and_return(double("Job", name: "Test Job"))
      allow(Sidekiq::Cron::Job).to receive(:all).and_return([])
    end

    it "installs jobs without errors" do
      expect { foreman.install_jobs }.not_to raise_error
    end

    it "creates the correct number of jobs" do
      expect(Sidekiq::Cron::Job).to receive(:create).once
      foreman.install_jobs
    end
  end
end
