class CreateManufacturers < ActiveRecord::Migration[7.2]
  def change
    create_table :manufacturers do |t|
      t.references :country, null: false, foreign_key: true
      t.string :name
      t.string :location

      t.timestamps
    end
  end
end
