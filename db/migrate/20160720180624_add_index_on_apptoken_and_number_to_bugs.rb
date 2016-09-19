class AddIndexOnApptokenAndNumberToBugs < ActiveRecord::Migration
  def change
    add_index :bugs, [:application_token, :number], :unique => true
  end
end
