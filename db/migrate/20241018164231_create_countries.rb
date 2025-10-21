class CreateCountries < ActiveRecord::Migration[7.2]
  def change
    create_table :countries do |t|
      t.string :name
      t.references :country, null: true, foreign_key: true

      t.timestamps
    end
  end
end
