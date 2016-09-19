class CreateBugs < ActiveRecord::Migration
  def change
    create_table :bugs do |t|
      t.string :application_token
      t.integer :number
      t.string :status
      t.string :priority
      t.text :comment

      t.timestamps null: false
    end
  end
end
