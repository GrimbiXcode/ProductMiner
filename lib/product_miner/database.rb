# frozen_string_literal: true

require "sequel"
require_relative "config"
require_relative "models/price_record"

module ProductMiner
  # Database connection manager
  class Database
    attr_reader :db, :price_records

    def initialize(config = nil)
      @config = config || Config.new
      @db = connect
      @price_records = Models::PriceRecord.new(@db)
    end

    def connect
      db_config = @config.database_config
      adapter = db_config["adapter"] || "postgres"

      case adapter
      when "postgresql", "postgres"
        Sequel.postgres(
          host: db_config["host"] || "localhost",
          port: db_config["port"] || 5432,
          database: db_config["database"] || "product_miner",
          user: db_config["username"] || "postgres",
          password: db_config["password"] || "postgres",
          pool: db_config["pool"] || 5,
          timeout: db_config["timeout"] || 5000
        )
      when "sqlite"
        Sequel.sqlite(db_config["database"] || "product_miner.db")
      else
        raise "Unsupported database adapter: #{adapter}"
      end
    end

    def test_connection
      @db.test_connection
    rescue Sequel::DatabaseConnectionError => e
      raise "Database connection failed: #{e.message}"
    end

    def close
      @db.disconnect
    end
  end
end
