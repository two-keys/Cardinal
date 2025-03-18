# frozen_string_literal: true

class AddTitleToEntitlement < ActiveRecord::Migration[7.2]
  def change
    add_column :entitlements, :title, :string, null: true
    add_index :entitlements, :title
  end
end
