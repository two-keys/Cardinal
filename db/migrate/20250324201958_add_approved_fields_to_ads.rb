class AddApprovedFieldsToAds < ActiveRecord::Migration[7.2]
  def change
    add_column :ads, :approved_url, :string
    add_column :ads, :pending_approval, :boolean, null: false, default: true
  end
end
