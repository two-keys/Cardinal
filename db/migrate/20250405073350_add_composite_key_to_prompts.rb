class AddCompositeKeyToPrompts < ActiveRecord::Migration[7.2]
  def change
    add_index :prompts, [:bumped_at]
    add_index :prompts, [:bumped_at, :status, :user_id, :managed], unique: false
  end
end
