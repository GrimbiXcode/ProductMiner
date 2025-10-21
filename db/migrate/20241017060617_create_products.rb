class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description, null: true
      t.text :details, null: true
      t.references :product_type, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
