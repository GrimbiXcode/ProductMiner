# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/product_miner/foreman/foreman"
require_relative "../../lib/product_miner/config"
require_relative "../../lib/product_miner/database"

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

RSpec.describe Foreman do
  let(:config_data) do
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

  let(:config) { SimpleConfig.new(config_data) }
  let(:foreman) { described_class.new(config) }

  describe "#initialize" do
    it "initializes with a config object" do
      expect(foreman.instance_variable_get(:@config)).to eq(config)
    end

    it "initializes with default config when none provided" do
      foreman = described_class.new
      expect(foreman.instance_variable_get(:@config)).to be_a(ProductMiner::Config)
    end

    it "initializes logger" do
      expect(foreman.instance_variable_get(:@logger)).to be_a(Logger)
    end
  end

  describe "#perform" do
    let(:product_id) { "204451300000" }
    let(:mock_data) do
      {
        "id" => product_id,
        "name" => "Test Product",
        "price" => { "value" => 10.99, "currency" => "CHF" }
      }
    end

    before do
      # Mock Sidekiq testing mode
      allow(Sidekiq::Testing).to receive(:fake!).and_return(nil)
      
      # Mock the database
      mock_db = double("Database")
      mock_price_records = double("PriceRecords")
      
      allow(mock_db).to receive(:price_records).and_return(mock_price_records)
      allow(mock_price_records).to receive(:save).and_return(true)
      
      allow(foreman).to receive(:setup_database).and_return(mock_db)
      allow(foreman).to receive(:setup_redis).and_return(nil)
      allow(foreman).to receive(:fetch_product_data).and_return(mock_data)
      allow(foreman).to receive(:save_price_record).and_return(nil)
    end

    it "calls setup_redis and setup_database" do
      expect(foreman).to receive(:setup_redis)
      expect(foreman).to receive(:setup_database)
      foreman.perform("migros", product_id)
    end

    it "fetches product data" do
      expect(foreman).to receive(:fetch_product_data).with("migros", product_id)
      foreman.perform("migros", product_id)
    end

    it "saves price record" do
      expect(foreman).to receive(:save_price_record).with("migros", product_id, mock_data)
      foreman.perform("migros", product_id)
    end

    context "when an error occurs" do
      before do
        allow(foreman).to receive(:fetch_product_data).and_raise(StandardError.new("Test error"))
      end

      it "logs the error" do
        expect(foreman.instance_variable_get(:@logger)).to receive(:error).with(/Error mining migros:204451300000: Test error/)
        expect { foreman.perform("migros", product_id) }.to raise_error(StandardError)
      end

      it "re-raises the error" do
        expect { foreman.perform("migros", product_id) }.to raise_error(StandardError, "Test error")
      end
    end
  end

  describe "#install_jobs" do
    before do
      allow(Sidekiq::Testing).to receive(:fake!).and_return(nil)
      allow(foreman).to receive(:setup_redis).and_return(nil)
      allow(Sidekiq::Cron::Job).to receive(:destroy_all!).and_return(nil)
      allow(Sidekiq::Cron::Job).to receive(:create).and_return(double("Job", name: "Test Job"))
      allow(Sidekiq::Cron::Job).to receive(:all).and_return([])
    end

    it "destroys all existing jobs" do
      expect(Sidekiq::Cron::Job).to receive(:destroy_all!)
      foreman.install_jobs
    end

    it "creates jobs for enabled products" do
      expect(Sidekiq::Cron::Job).to receive(:create).with(
        hash_including(
          name: "Migros Miner - 204451300000",
          cron: "* * * * *",
          class: "Foreman",
          args: ["MIGROS", "204451300000"]
        )
      )
      foreman.install_jobs
    end

    it "logs job installation" do
      expect(foreman.instance_variable_get(:@logger)).to receive(:info).with(/Installing job: Migros Miner - 204451300000/)
      foreman.install_jobs
    end
  end

  describe "#fetch_product_data" do
    let(:product_id) { "204451300000" }
    let(:mock_migros_api) { double("MigrosApi") }

    before do
      allow(MigrosApi).to receive(:new).and_return(mock_migros_api)
    end

    context "with migros miner" do
      let(:mock_data) { { "id" => product_id, "name" => "Test" } }

      before do
        allow(mock_migros_api).to receive(:read_product_details).with(product_id).and_return(mock_data)
      end

      it "returns product data from MigrosApi" do
        result = foreman.send(:fetch_product_data, "migros", product_id)
        expect(result).to eq(mock_data)
      end
    end

    context "with unknown miner" do
      it "returns empty hash" do
        expect(foreman.instance_variable_get(:@logger)).to receive(:warn).with(/Miner unknown_miner not known/)
        result = foreman.send(:fetch_product_data, "unknown_miner", product_id)
        expect(result).to eq({})
      end
    end
  end

  describe "#save_price_record" do
    let(:product_id) { "204451300000" }
    let(:miner) { "migros" }
    let(:data) do
      {
        "id" => product_id,
        "name" => "Test Product",
        "price" => { "value" => 10.99, "currency" => "CHF" },
        "originalPrice" => { "value" => 12.99 }
      }
    end
    let(:mock_db) { double("Database") }
    let(:mock_price_records) { double("PriceRecords") }

    before do
      allow(foreman).to receive(:setup_database).and_return(mock_db)
      allow(mock_db).to receive(:price_records).and_return(mock_price_records)
      allow(mock_price_records).to receive(:save).and_return(true)
    end

    it "extracts and saves price record" do
      expected_record = {
        product_id: product_id,
        product_name: "Test Product",
        miner: "migros",
        price: 10.99,
        original_price: 12.99,
        currency: "CHF",
        product_data: data.to_json,
        recorded_at: kind_of(Time)
      }

      expect(mock_price_records).to receive(:save).with(expected_record)
      foreman.send(:save_price_record, miner, product_id, data)
    end

    context "with empty data" do
      it "does not save record" do
        expect(mock_price_records).not_to receive(:save)
        foreman.send(:save_price_record, miner, product_id, {})
      end
    end

    context "with nil data" do
      it "does not save record" do
        expect(mock_price_records).not_to receive(:save)
        foreman.send(:save_price_record, miner, product_id, nil)
      end
    end
  end

  describe "price extraction methods" do
    let(:data) do
      {
        "price" => { "value" => 10.99, "currency" => "CHF", "originalValue" => 12.99 },
        "name" => "Test Product"
      }
    end

    describe "#extract_price" do
      it "extracts price from price.value" do
        expect(foreman.send(:extract_price, data)).to eq(10.99)
      end

      it "extracts price from currentPrice.value as fallback" do
        data_no_price = { "currentPrice" => { "value" => 15.99 } }
        expect(foreman.send(:extract_price, data_no_price)).to eq(15.99)
      end

      it "returns 0.0 when no price found" do
        expect(foreman.send(:extract_price, {})).to eq(0.0)
      end
    end

    describe "#extract_original_price" do
      it "extracts original price from price.originalValue" do
        expect(foreman.send(:extract_original_price, data)).to eq(12.99)
      end

      it "extracts original price from originalPrice.value" do
        data_alt = { "originalPrice" => { "value" => 14.99 } }
        expect(foreman.send(:extract_original_price, data_alt)).to eq(14.99)
      end

      it "returns nil when no original price found" do
        expect(foreman.send(:extract_original_price, {})).to be_nil
      end
    end

    describe "#extract_currency" do
      it "extracts currency from price.currency" do
        expect(foreman.send(:extract_currency, data)).to eq("CHF")
      end

      it "returns CHF as default" do
        expect(foreman.send(:extract_currency, {})).to eq("CHF")
      end
    end

    describe "#extract_product_name" do
      it "extracts name from name field" do
        expect(foreman.send(:extract_product_name, data)).to eq("Test Product")
      end

      it "extracts name from title field as fallback" do
        data_alt = { "title" => "Alt Product" }
        expect(foreman.send(:extract_product_name, data_alt)).to eq("Alt Product")
      end

      it "returns 'Unknown Product' when no name found" do
        expect(foreman.send(:extract_product_name, {})).to eq("Unknown Product")
      end
    end
  end
end
