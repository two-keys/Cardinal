class AddIconChatUniqueIndexToChatUsers < ActiveRecord::Migration[7.2]
  def change
    add_index :chat_users, [:icon, :chat_id], unique: true
  end
end
