class AddHideLatestToChatUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :chat_users, :hide_latest, :boolean, null: false, default: false
  end
end
