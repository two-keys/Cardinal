class AddGroupChatVisibility < ActiveRecord::Migration[7.0]
  def change
    add_column :chat_users, :role, :integer, default: 0
    add_column :connect_codes, :status, :integer, default: 0
    add_reference :chats, :prompt, null: true, foreign_key: true
    
    add_index :chat_users, :role
    add_index :connect_codes, :status
  end
end
