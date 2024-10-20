class CreateSellingUnits < ActiveRecord::Migration[7.2]
  def change
    create_table :selling_units do |t|
      t.references :product, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: true
      t.references :manufacturer, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.references :currency, null: false, foreign_key: true
      t.decimal :amount

      t.timestamps
    end
  end
end
