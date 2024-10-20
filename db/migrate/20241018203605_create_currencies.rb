class CreateCurrencies < ActiveRecord::Migration[7.2]
  def change
    create_table :currencies do |t|
      t.string :name
      t.string :label
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end
  end
end
