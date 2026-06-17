# frozen_string_literal: true

require_relative "product_miner/version"
require_relative "product_miner/config"
require_relative "product_miner/database"
require_relative "product_miner/miners/migros_api"
require_relative "product_miner/foreman/foreman"

# Product Miner Module
module ProductMiner
  class Error < StandardError; end

  # Product Miner Class
  class ProductMiner
    attr_reader :config, :foreman, :database

    def initialize(config_path = nil)
      @config = ProductMiner::Config.new(config_path)
      # Skip database initialization in test environment
      @database = ProductMiner::Database.new(@config) unless ENV["RACK_ENV"] == "test"
      @foreman = Foreman.new(@config)
      @foreman.install_jobs unless ENV["RACK_ENV"] == "test"
    end

    def mine(product_id = nil)
      product_id ||= @config.products.first&.[]("id") || "204451300000"
      @foreman.perform(:migros, product_id)
    end

    def run_once
      @config.enabled_products.each do |product|
        miner = product["miner"] || "migros"
        product_id = product["id"]
        @foreman.perform(miner.to_sym, product_id)
      end
    end
  end
end
