# frozen_string_literal: true

require "sequel"
require_relative "config"
require_relative "models/price_record"

module ProductMiner
  # Database connection manager
  class Database
    def initialize(config = nil)
      @config = config || Config.new
      @db_connection = nil
      @price_records = nil
    end

    def connect
      return @db_connection if @db_connection

      db_config = @config.database_config
      adapter = db_config["adapter"] || "postgres"

      @db_connection = case adapter
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

      @price_records = Models::PriceRecord.new(@db_connection)
      @db_connection
    end

    def db
      connect unless @db_connection
      @db_connection
    end

    def price_records
      connect unless @price_records
      @price_records
    end

    def test_connection
      connect
      @db_connection.test_connection
    rescue Sequel::DatabaseConnectionError => e
      raise "Database connection failed: #{e.message}"
    end

    def close
      @db_connection&.disconnect
    end
  end
end
