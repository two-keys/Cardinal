class AddCompositeKeyToPrompts < ActiveRecord::Migration[7.2]
  def change
    add_index :filters, [:target_type, :target_id, :filter_type, :group, :user_id, :priority]
    add_index :prompts, [:bumped_at]
    add_index :prompts, [:bumped_at, :status, :user_id, :managed], unique: false
  end
end
