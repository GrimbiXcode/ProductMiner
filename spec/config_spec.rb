# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/product_miner/config"

RSpec.describe ProductMiner::Config do
  let(:config_path) { File.expand_path("../../../config/default.yml", __FILE__) }
  let(:config) { described_class.new(config_path) }

  describe "#initialize" do
    it "loads config from file" do
      expect(config.data).to be_a(Hash)
    end

    it "uses default path when none provided" do
      config = described_class.new
      expect(config.instance_variable_get(:@config_path)).to eq(ProductMiner::Config::DEFAULT_CONFIG_PATH)
    end
  end

  describe "#load_config" do
    context "when config file exists" do
      it "returns parsed YAML as hash" do
        expect(config.data).to be_a(Hash)
      end

      it "loads expected sections" do
        expect(config.data).to include("redis", "database", "products", "scheduler", "logging")
      end
    end

    context "when config file does not exist" do
      it "returns empty hash" do
        config = described_class.new("/nonexistent/path.yml")
        expect(config.data).to eq({})
      end
    end
  end

  describe "accessor methods" do
    it "responds to redis_config" do
      expect(config.redis_config).to be_a(Hash)
      expect(config.redis_config).to include("host", "port", "db")
    end

    it "responds to database_config" do
      expect(config.database_config).to be_a(Hash)
    end

    it "responds to products" do
      expect(config.products).to be_a(Array)
    end

    it "responds to enabled_products" do
      expect(config.enabled_products).to be_a(Array)
      expect(config.enabled_products).to all(include("enabled" => true))
    end

    it "responds to scheduler_config" do
      expect(config.scheduler_config).to be_a(Hash)
    end

    it "responds to miner_config" do
      expect(config.miner_config("migros")).to be_a(Hash)
    end

    it "responds to logging_config" do
      expect(config.logging_config).to be_a(Hash)
    end
  end

  describe "#[]" do
    it "accesses config data by key" do
      expect(config["redis"]).to be_a(Hash)
    end

    it "returns nil for unknown keys" do
      expect(config["unknown_key"]).to be_nil
    end
  end

  describe "#dig" do
    it "digs into nested config data" do
      expect(config.dig("redis", "host")).to eq("localhost")
    end

    it "returns nil for unknown nested keys" do
      expect(config.dig("unknown", "nested", "key")).to be_nil
    end
  end

  describe "#method_missing" do
    it "allows access to config keys as methods" do
      expect(config.redis).to be_a(Hash)
    end

    it "allows access to nested config keys" do
      expect(config.database).to be_a(Hash)
    end

    it "returns nil for unknown methods" do
      expect(config.unknown_method).to be_nil
    end
  end

  describe "#respond_to_missing?" do
    it "returns true for existing config keys" do
      expect(config.respond_to?(:redis)).to be true
    end

    it "returns false for unknown keys" do
      expect(config.respond_to?(:unknown_key)).to be false
    end
  end

  describe "default values" do
    it "provides default redis config" do
      config = described_class.new("/nonexistent/path.yml")
      expect(config.redis_config).to eq({ host: "localhost", port: 6379, db: 1 })
    end

    it "provides default database config" do
      config = described_class.new("/nonexistent/path.yml")
      expect(config.database_config).to eq({})
    end

    it "provides default products" do
      config = described_class.new("/nonexistent/path.yml")
      expect(config.products).to eq([])
    end

    it "provides default scheduler config" do
      config = described_class.new("/nonexistent/path.yml")
      expect(config.scheduler_config).to eq({})
    end

    it "provides default logging config" do
      config = described_class.new("/nonexistent/path.yml")
      expect(config.logging_config).to eq({ level: "info" })
    end
  end

  describe "enabled_products filtering" do
    let(:config_with_disabled) do
      config_data = {
        "products" => [
          { "id" => "1", "enabled" => true },
          { "id" => "2", "enabled" => false },
          { "id" => "3" }  # enabled by default
        ]
      }
      
      # Create a temporary config file
      temp_file = Tempfile.new(["config", ".yml"])
      temp_file.write(config_data.to_yaml)
      temp_file.close
      
      described_class.new(temp_file.path)
    end

    after do
      # Clean up temp file
      File.delete(config_with_disabled.instance_variable_get(:@config_path)) if File.exist?(config_with_disabled.instance_variable_get(:@config_path))
    end

    it "filters out disabled products" do
      enabled = config_with_disabled.enabled_products
      expect(enabled.length).to eq(2)
      expect(enabled.map { |p| p["id"] }).to include("1", "3")
      expect(enabled.map { |p| p["id"] }).not_to include("2")
    end
  end
end
