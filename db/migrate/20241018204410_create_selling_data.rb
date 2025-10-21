class CreateSellingData < ActiveRecord::Migration[7.2]
  def change
    create_table :selling_data do |t|
      t.references :selling_unit, null: false, foreign_key: true
      t.datetime :recorded_at
      t.decimal :value

      t.timestamps
    end
  end
end
