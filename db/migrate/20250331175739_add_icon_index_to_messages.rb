class AddIconIndexToMessages < ActiveRecord::Migration[7.2]
  def change
    add_index :messages, :icon
  end
end
