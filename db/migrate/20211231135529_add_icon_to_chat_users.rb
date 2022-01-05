class AddIconToChatUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :chat_users do |t|
      t.column :icon, :string
    end
  end
end
