class CreateRelationTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :relation_types do |t|
      t.string :name
      t.text :description
      t.text :formula

      t.timestamps
    end
  end
end
