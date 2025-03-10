class AddTitleAndDescriptionToConnectCode < ActiveRecord::Migration[7.2]
  def change
    add_column :connect_codes, :title, :string
    add_column :connect_codes, :description, :text
  end
end
