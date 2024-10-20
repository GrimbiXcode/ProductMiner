# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_10_18_204410) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_currencies_on_country_id"
  end

  create_table "manufacturers", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_manufacturers_on_country_id"
  end

  create_table "product_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry"
    t.index ["ancestry"], name: "index_product_types_on_ancestry"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "details"
    t.bigint "product_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
  end

  create_table "selling_data", force: :cascade do |t|
    t.bigint "selling_unit_id", null: false
    t.datetime "recorded_at"
    t.decimal "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["selling_unit_id"], name: "index_selling_data_on_selling_unit_id"
  end

  create_table "selling_units", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "vendor_id", null: false
    t.bigint "manufacturer_id", null: false
    t.bigint "unit_id", null: false
    t.bigint "currency_id", null: false
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_selling_units_on_currency_id"
    t.index ["manufacturer_id"], name: "index_selling_units_on_manufacturer_id"
    t.index ["product_id"], name: "index_selling_units_on_product_id"
    t.index ["unit_id"], name: "index_selling_units_on_unit_id"
    t.index ["vendor_id"], name: "index_selling_units_on_vendor_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.string "si_unit"
    t.string "formula_to_si"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vendors", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_vendors_on_country_id"
  end

  add_foreign_key "currencies", "countries"
  add_foreign_key "manufacturers", "countries"
  add_foreign_key "products", "product_types"
  add_foreign_key "selling_data", "selling_units"
  add_foreign_key "selling_units", "currencies"
  add_foreign_key "selling_units", "manufacturers"
  add_foreign_key "selling_units", "products"
  add_foreign_key "selling_units", "units"
  add_foreign_key "selling_units", "vendors"
  add_foreign_key "vendors", "countries"
end
