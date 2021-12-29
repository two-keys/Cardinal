# frozen_string_literal: true

class AddFieldsToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :username, null: false, default: '', unique: true
      t.boolean :admin, default: false
      t.boolean :verified, default: false
      t.datetime :unban_at, default: nil
      t.string :ban_reason, default: nil
      t.datetime :delete_at, default: nil
    end
  end
end
