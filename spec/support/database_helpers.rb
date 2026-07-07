# frozen_string_literal: true

require "sequel"

module DatabaseHelpers
  def setup_test_database
    @test_db = Sequel.sqlite(:memory:)
    
    # Create all necessary tables
    @test_db.create_table :price_records do
      primary_key :id
      String :product_id, null: false
      String :product_name, null: true
      String :miner, null: false
      Float :price, null: false
      Float :original_price, null: true
      String :currency, null: false, default: "CHF"
      String :product_data, null: true
      DateTime :recorded_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      index [:product_id, :recorded_at]
      index [:miner, :recorded_at]
    end
    
    @test_db
  end

  def teardown_test_database
    @test_db&.disconnect
    @test_db = nil
  end

  def insert_price_record(attributes = {})
    defaults = {
      product_id: "204451300000",
      product_name: "Test Product",
      miner: "migros",
      price: 10.99,
      original_price: 12.99,
      currency: "CHF",
      product_data: '{"id": "204451300000", "name": "Test Product"}',
      recorded_at: Time.now.utc
    }
    
    @test_db[:price_records].insert(defaults.merge(attributes))
  end
end

RSpec.configure do |config|
  config.include DatabaseHelpers, type: :database
  config.include DatabaseHelpers, type: :integration
end
