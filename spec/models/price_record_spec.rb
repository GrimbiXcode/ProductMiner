# frozen_string_literal: true

require "spec_helper"
require "sequel"
require_relative "../../lib/product_miner/models/price_record"

RSpec.describe ProductMiner::Models::PriceRecord do
  let(:db) { Sequel.sqlite(:memory:) }
  let(:price_record) { described_class.new(db) }

  describe "#initialize" do
    it "initializes with database connection" do
      expect(price_record.db).to eq(db)
    end

    it "creates table on initialization" do
      expect(db.table_exists?(:price_records)).to be true
    end
  end

  describe "#create_table" do
    let(:new_db) { Sequel.sqlite(:memory:) }
    let(:new_price_record) { described_class.new(new_db) }

    before do
      # Drop table if it exists
      new_db.drop_table?(:price_records)
    end

    it "creates price_records table with all required columns" do
      new_price_record.create_table
      
      table = new_db[:price_records]
      columns = table.columns.map(&:to_s)
      
      expect(columns).to include("id")
      expect(columns).to include("product_id")
      expect(columns).to include("product_name")
      expect(columns).to include("miner")
      expect(columns).to include("price")
      expect(columns).to include("original_price")
      expect(columns).to include("currency")
      expect(columns).to include("product_data")
      expect(columns).to include("recorded_at")
    end

    it "creates indexes" do
      new_price_record.create_table
      
      indexes = new_db.indexes(:price_records)
      index_names = indexes.map { |name, _| name }
      
      expect(index_names).to include("price_records_product_id_recorded_at_index")
      expect(index_names).to include("price_records_miner_recorded_at_index")
    end
  end

  describe "#table_exists?" do
    it "returns true when table exists" do
      expect(price_record.table_exists?).to be true
    end

    it "returns false when table does not exist" do
      new_db = Sequel.sqlite(:memory:)
      new_price_record = described_class.new(new_db)
      new_db.drop_table?(:price_records)
      expect(new_price_record.table_exists?).to be false
    end
  end

  describe "#save" do
    let(:record) do
      {
        product_id: "204451300000",
        product_name: "Test Product",
        miner: "migros",
        price: 10.99,
        original_price: 12.99,
        currency: "CHF",
        product_data: '{"id": "204451300000", "name": "Test Product"}',
        recorded_at: Time.now.utc
      }
    end

    it "saves record to database" do
      price_record.save(record)
      
      saved = db[:price_records].first
      expect(saved[:product_id]).to eq("204451300000")
      expect(saved[:product_name]).to eq("Test Product")
      expect(saved[:miner]).to eq("migros")
      expect(saved[:price]).to eq(10.99)
      expect(saved[:original_price]).to eq(12.99)
      expect(saved[:currency]).to eq("CHF")
    end

    it "saves multiple records" do
      record2 = record.merge(product_id: "204451300001", price: 15.99)
      
      price_record.save(record)
      price_record.save(record2)
      
      expect(db[:price_records].count).to eq(2)
    end
  end

  describe "#find_by_product_id" do
    let(:record1) do
      {
        product_id: "204451300000",
        product_name: "Test Product",
        miner: "migros",
        price: 10.99,
        currency: "CHF",
        recorded_at: Time.now.utc - 3600
      }
    end

    let(:record2) do
      {
        product_id: "204451300000",
        product_name: "Test Product",
        miner: "migros",
        price: 12.99,
        currency: "CHF",
        recorded_at: Time.now.utc
      }
    end

    before do
      price_record.save(record1)
      price_record.save(record2)
    end

    it "finds records by product_id" do
      results = price_record.find_by_product_id("204451300000")
      expect(results.length).to eq(2)
    end

    it "orders by recorded_at ascending by default" do
      results = price_record.find_by_product_id("204451300000")
      expect(results[0][:price]).to eq(10.99)
      expect(results[1][:price]).to eq(12.99)
    end

    it "limits results" do
      results = price_record.find_by_product_id("204451300000", limit: 1)
      expect(results.length).to eq(1)
    end

    it "returns empty array for non-existent product_id" do
      results = price_record.find_by_product_id("nonexistent")
      expect(results).to eq([])
    end
  end

  describe "#find_recent" do
    let(:old_record) do
      {
        product_id: "204451300000",
        product_name: "Test Product",
        miner: "migros",
        price: 10.99,
        currency: "CHF",
        recorded_at: Time.now.utc - 7200  # 2 hours ago
      }
    end

    let(:recent_record) do
      {
        product_id: "204451300001",
        product_name: "Recent Product",
        miner: "migros",
        price: 15.99,
        currency: "CHF",
        recorded_at: Time.now.utc - 1800  # 30 minutes ago
      }
    end

    before do
      price_record.save(old_record)
      price_record.save(recent_record)
    end

    it "finds records within time window" do
      results = price_record.find_recent(hours: 1)
      expect(results.length).to eq(1)
      expect(results[0][:product_id]).to eq("204451300001")
    end

    it "filters by miner" do
      results = price_record.find_recent(miner: "migros", hours: 24)
      expect(results.length).to eq(2)
    end

    it "orders by recorded_at" do
      results = price_record.find_recent(hours: 24)
      expect(results[0][:recorded_at]).to be < results[1][:recorded_at]
    end
  end

  describe "#latest_price" do
    let(:record1) do
      {
        product_id: "204451300000",
        product_name: "Test Product",
        miner: "migros",
        price: 10.99,
        currency: "CHF",
        recorded_at: Time.now.utc - 3600
      }
    end

    let(:record2) do
      {
        product_id: "204451300000",
        product_name: "Test Product",
        miner: "migros",
        price: 12.99,
        currency: "CHF",
        recorded_at: Time.now.utc
      }
    end

    before do
      price_record.save(record1)
      price_record.save(record2)
    end

    it "returns the latest record for a product" do
      result = price_record.latest_price("204451300000")
      expect(result[:price]).to eq(12.99)
    end

    it "returns nil for non-existent product" do
      result = price_record.latest_price("nonexistent")
      expect(result).to be_nil
    end
  end
end
