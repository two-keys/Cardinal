class AddFieldsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :username, :string, null: false
    add_column :users, :admin, :boolean, default: false
    add_column :users, :verified, :boolean, default: false
    add_column :users, :unban_at, :datetime, default: nil
    add_column :users, :ban_reason, :string, default: nil
    add_column :users, :delete_at, :datetime, default: nil
  end
end
