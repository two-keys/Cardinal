class CreateModChats < ActiveRecord::Migration[7.2]
  def change
    create_table :mod_chats do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :mod_chats, :status
    add_index :mod_chats, [:user_id, :chat_id]
  end
end
