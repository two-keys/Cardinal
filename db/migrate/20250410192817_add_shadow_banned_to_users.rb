class AddShadowBannedToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :shadowbanned, :boolean, null: false, default: false
    add_index :users, [:shadowbanned]
  end
end
