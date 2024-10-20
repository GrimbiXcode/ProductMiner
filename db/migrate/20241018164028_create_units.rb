class CreateUnits < ActiveRecord::Migration[7.2]
  def change
    create_table :units do |t|
      t.string :name
      t.string :si_unit
      t.string :formula_to_si

      t.timestamps
    end
  end
end
