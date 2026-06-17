# frozen_string_literal: true

require "spec_helper"
require "yaml"
require_relative "../lib/product_miner/config"

RSpec.describe ProductMiner::Config do
  let(:config_path) { File.expand_path("../config/default.yml", __dir__) }
  let(:config) { described_class.new(config_path) }

  describe "#initialize" do
    it "loads the default config file" do
      expect(config.data).to be_a(Hash)
      expect(config.data).not_to be_empty
    end

    context "when config file does not exist" do
      it "returns empty hash" do
        nonexistent_config = described_class.new("/nonexistent/path.yml")
        expect(nonexistent_config.data).to eq({})
      end
    end
  end

  describe "#[]" do
    it "accesses config values by key" do
      expect(config["redis"]).to be_a(Hash)
      expect(config["products"]).to be_a(Array)
    end
  end

  describe "#dig" do
    it "accesses nested config values" do
      expect(config.dig("redis", "host")).to eq("localhost")
      expect(config.dig("database", "adapter")).to eq("postgresql")
    end
  end

  describe "#redis_config" do
    it "returns redis configuration" do
      redis = config.redis_config
      expect(redis["host"]).to eq("localhost")
      expect(redis["port"]).to eq(6379)
      expect(redis["db"]).to eq(1)
    end
  end

  describe "#database_config" do
    it "returns database configuration" do
      db_config = config.database_config
      expect(db_config["adapter"]).to eq("postgresql")
      expect(db_config["database"]).to eq("product_miner")
    end
  end

  describe "#products" do
    it "returns array of products" do
      products = config.products
      expect(products).to be_a(Array)
      expect(products.first["id"]).to eq("204451300000")
    end
  end

  describe "#enabled_products" do
    it "returns only enabled products" do
      enabled = config.enabled_products
      expect(enabled).to be_a(Array)
      enabled.each do |product|
        expect(product["enabled"]).not_to eq(false)
      end
    end
  end

  describe "#scheduler_config" do
    it "returns scheduler configuration" do
      scheduler = config.scheduler_config
      expect(scheduler["migros"]).to be_a(Hash)
      expect(scheduler.dig("migros", "cron")).to eq("* * * * *")
    end
  end

  describe "#miner_config" do
    it "returns miner-specific configuration" do
      migros_config = config.miner_config("migros")
      expect(migros_config["enabled"]).to eq(true)
      expect(migros_config["base_url"]).to eq("https://www.migros.ch")
    end

    it "returns empty hash for unknown miner" do
      expect(config.miner_config("unknown")).to eq({})
    end
  end

  describe "#logging_config" do
    it "returns logging configuration" do
      logging = config.logging_config
      expect(logging["level"]).to eq("info")
      expect(logging["file"]).to eq("log/product_miner.log")
    end
  end
end
