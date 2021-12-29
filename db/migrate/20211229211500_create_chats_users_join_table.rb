class CreateChatsUsersJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_table :chats_users do |t|
      t.belongs_to :chat, index: true
      t.belongs_to :user, index: true

      t.string :title
      t.text :description
      t.integer :status, default: 0 # 0: ongoing, 1: unanswered, 2: unread, 3: ended
    end
  end
end
