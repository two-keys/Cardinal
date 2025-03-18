# frozen_string_literal: true

class CreateUserEntitlements < ActiveRecord::Migration[7.2]
  def change
    create_table :user_entitlements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :entitlement, null: false, foreign_key: true
      t.datetime :expires_on

      t.timestamps
    end
    add_index :user_entitlements, %i[user_id entitlement_id], unique: true
  end
end
