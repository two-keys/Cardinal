# frozen_string_literal: true

class AddFieldsToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :table, bulk: true do |t|
      t.string :username, :string, null: false, default: '', unique: true
      t.boolean :admin, :boolean, default: false
      t.boolean :verified, :boolean, default: false
      t.datetime :unban_at, :datetime, default: nil
      t.string :ban_reason, :string, default: nil
      t.datetime :delete_at, :datetime, default: nil
    end
  end
end
