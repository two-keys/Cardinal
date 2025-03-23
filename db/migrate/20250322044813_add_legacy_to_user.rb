class AddLegacyToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :legacy, :boolean, null: false, default: false
  end
end
