class AddManagedToPrompts < ActiveRecord::Migration[7.0]
  def change
    add_column :prompts, :managed, :boolean, default: false, null: false
    add_index :prompts, :managed
  end
end
