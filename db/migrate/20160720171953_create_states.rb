class CreateStates < ActiveRecord::Migration
  def change
    create_table :states do |t|
      t.string :device
      t.string :os
      t.integer :memory
      t.integer :storage

      t.timestamps null: false
    end
  end
end
