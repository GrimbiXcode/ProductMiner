class CreateRelations < ActiveRecord::Migration[7.2]
  def change
    create_table :relations do |t|
      t.bigint :source_product_id
      t.bigint :destination_product_id
      t.references :relation_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
