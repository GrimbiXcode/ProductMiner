class AddRelationRefToRelationAndProduct < ActiveRecord::Migration[7.2]
  def change
    add_index :relations, :source_product_id
    add_index :relations, :destination_product_id
    add_index :relations, [:source_product_id, :destination_product_id, :relation_type_id], unique: true

    add_foreign_key :relations, :products, column: :source_product_id
    add_foreign_key :relations, :products, column: :destination_product_id
  end
end
