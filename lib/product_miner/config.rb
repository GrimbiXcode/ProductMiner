# frozen_string_literal: true

require "yaml"

module ProductMiner
  # Configuration manager for ProductMiner
  class Config
    DEFAULT_CONFIG_PATH = File.expand_path("../../../config/default.yml", __FILE__)

    attr_reader :data

    def initialize(config_path = nil)
      @config_path = config_path || DEFAULT_CONFIG_PATH
      @data = load_config
    end

    def load_config
      return {} unless File.exist?(@config_path)

      YAML.safe_load(File.read(@config_path)) || {}
    end

    def [](key)
      @data[key]
    end

    def dig(*keys)
      @data.dig(*keys)
    end

    def method_missing(name, *args)
      if name.to_s.end_with?("=")
        super
      else
        @data[name] || @data[name.to_s]
      end
    end

    def respond_to_missing?(name, include_private = false)
      @data.key?(name) || @data.key?(name.to_s) || super
    end

    def redis_config
      @data["redis"] || { host: "localhost", port: 6379, db: 1 }
    end

    def database_config
      @data["database"] || {}
    end

    def products
      @data["products"] || []
    end

    def enabled_products
      products.select { |p| p["enabled"] != false }
    end

    def scheduler_config
      @data["scheduler"] || {}
    end

    def miner_config(miner_name)
      @data.dig("miners", miner_name) || {}
    end

    def logging_config
      @data["logging"] || { level: "info" }
    end
  end
end
