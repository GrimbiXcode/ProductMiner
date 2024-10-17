class AddPathToProductType < ActiveRecord::Migration[7.2]
  def change
    add_column :product_types, :ancestry, :string
    add_index :product_types, :ancestry
  end
end
