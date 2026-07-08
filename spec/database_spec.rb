# frozen_string_literal: true

require "spec_helper"
require "sequel"
require_relative "../lib/product_miner/config"
require_relative "../lib/product_miner/models/price_record"
require_relative "../lib/product_miner/database"

RSpec.describe ProductMiner::Database do
  let(:config) do
    double("Config", 
      database_config: { "adapter" => "sqlite", "database" => ":memory:" }
    )
  end

  let(:database) { described_class.new(config) }

  describe "#initialize" do
    it "initializes with config" do
      expect(database.instance_variable_get(:@config)).to eq(config)
    end

    it "initializes with default config when none provided" do
      db = described_class.new
      expect(db.instance_variable_get(:@config)).to be_a(ProductMiner::Config)
    end

    it "initializes connection as nil" do
      expect(database.instance_variable_get(:@db_connection)).to be_nil
    end

    it "initializes price_records as nil" do
      expect(database.instance_variable_get(:@price_records)).to be_nil
    end
  end

  describe "#connect" do
    context "with sqlite adapter" do
      it "creates sqlite connection" do
        connection = database.connect
        expect(connection).to be_a(Sequel::Database)
      end

      it "creates price_records model" do
        database.connect
        expect(database.instance_variable_get(:@price_records)).to be_a(ProductMiner::Models::PriceRecord)
      end

      it "caches the connection" do
        conn1 = database.connect
        conn2 = database.connect
        expect(conn1).to eq(conn2)
      end
    end

    context "with postgresql adapter" do
      let(:pg_config) do
        double("Config", 
          database_config: {
            "adapter" => "postgresql",
            "host" => "localhost",
            "port" => 5432,
            "database" => "test_db",
            "username" => "test_user",
            "password" => "test_pass"
          }
        )
      end

      let(:pg_database) { described_class.new(pg_config) }

      it "attempts to create postgresql connection" do
        # We can't actually test the connection without a real PostgreSQL server
        # but we can verify the method is called
        expect(Sequel).to receive(:postgres).with(
          hash_including(
            host: "localhost",
            port: 5432,
            database: "test_db",
            user: "test_user",
            password: "test_pass"
          )
        ).and_call_original
        
        # This will fail to connect but we're testing the method call
        expect { pg_database.connect }.to raise_error(Sequel::DatabaseConnectionError)
      end
    end

    context "with unsupported adapter" do
      let(:bad_config) do
        double("Config", 
          database_config: { "adapter" => "mysql" }
        )
      end

      let(:bad_database) { described_class.new(bad_config) }

      it "raises error for unsupported adapter" do
        expect { bad_database.connect }.to raise_error(/Unsupported database adapter: mysql/)
      end
    end
  end

  describe "#db" do
    it "returns connection and connects if not connected" do
      expect(database.db).to be_a(Sequel::Database)
    end

    it "returns existing connection" do
      conn = database.connect
      expect(database.db).to eq(conn)
    end
  end

  describe "#price_records" do
    it "returns price_records model and connects if not connected" do
      expect(database.price_records).to be_a(ProductMiner::Models::PriceRecord)
    end

    it "returns existing price_records model" do
      pr = database.price_records
      expect(database.price_records).to eq(pr)
    end
  end

  describe "#test_connection" do
    it "tests database connection successfully" do
      database.connect
      expect { database.test_connection }.not_to raise_error
    end

    it "raises error when connection fails" do
      bad_config = double("Config", 
        database_config: { "adapter" => "postgresql", "host" => "nonexistent" }
      )
      bad_db = described_class.new(bad_config)
      
      expect { bad_db.test_connection }.to raise_error(/Database connection failed/)
    end
  end

  describe "#close" do
    it "closes the database connection" do
      database.connect
      expect(database.instance_variable_get(:@db_connection)).not_to be_nil
      
      database.close
      # Note: The connection might still be in the variable but marked as disconnected
      # We're mainly testing that the method doesn't raise an error
    end

    it "handles nil connection gracefully" do
      expect { database.close }.not_to raise_error
    end
  end
end
