# frozen_string_literal: true

require "sequel"

module ProductMiner
  module Models
    # PriceRecord model for storing product price history
    class PriceRecord
      attr_reader :db

      def initialize(db)
        @db = db
        create_table unless table_exists?
      end

      def create_table
        @db.create_table :price_records do
          primary_key :id
          String :product_id, null: false
          String :product_name, null: true
          String :miner, null: false  # e.g., 'migros'
          Float :price, null: false
          Float :original_price, null: true
          String :currency, null: false, default: "CHF"
          String :product_data, null: true  # JSON string for additional product info
          DateTime :recorded_at, null: false, default: Sequel::CURRENT_TIMESTAMP
          index [:product_id, :recorded_at]
          index [:miner, :recorded_at]
        end
      end

      def table_exists?
        @db.table_exists?(:price_records)
      end

      def save(record)
        @db[:price_records].insert(record)
      end

      def find_by_product_id(product_id, limit: 100)
        @db[:price_records]
           .where(product_id: product_id)
           .order(:recorded_at)
           .limit(limit)
           .all
      end

      def find_recent(miner: nil, hours: 24)
        query = @db[:price_records]
                   .where { recorded_at > Sequel::CURRENT_TIMESTAMP - (hours * 3600) }
                   .order(:recorded_at)
        query = query.where(miner: miner) if miner
        query.all
      end

      def latest_price(product_id)
        @db[:price_records]
           .where(product_id: product_id)
           .order(:recorded_at)
           .last
      end
    end
  end
end
