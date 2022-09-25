class AddDefaultSlotsToPrompts < ActiveRecord::Migration[7.0]
  def change
    add_column :prompts, :default_slots, :integer, default: 2, null: false
    add_index :prompts, :default_slots
  end
end
