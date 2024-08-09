# frozen_string_literal: true

require_relative "product_miner/version"
require_relative "product_miner/miners/migros_api"
require_relative "product_miner/foreman/foreman"

# Product Miner Module
module ProductMiner
  class Error < StandardError; end

  # Product Miner Class
  class ProductMiner
    def initialize
      # TODO: Initialize DB Connection
      Foreman.new.install_jobs
    end

    def mine
      foreman = Foreman.new
      foreman.perform(:migros, "204451300000")
    end
  end
  # MigrosApi.new({}).read_product_details("204451300000")
end

ProductMiner::ProductMiner.new
