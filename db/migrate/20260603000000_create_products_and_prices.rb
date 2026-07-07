# frozen_string_literal: true

require_relative "../db"

ActiveRecord::Schema.define do
  create_table :products, force: true do |t|
    t.string :external_id, null: false
    t.string :name
    t.string :store, null: false
    t.timestamps
  end

  create_table :prices, force: true do |t|
    t.references :product, null: false, foreign_key: true
    t.decimal :price, precision: 10, scale: 2
    t.datetime :recorded_at, null: false
    t.jsonb :metadata
  end
end
