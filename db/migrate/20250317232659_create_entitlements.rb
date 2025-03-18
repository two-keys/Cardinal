# frozen_string_literal: true

class CreateEntitlements < ActiveRecord::Migration[7.2]
  def change
    create_table :entitlements do |t|
      t.references :object, polymorphic: true, null: true
      t.string :flag, null: true
      t.string :data, null: true

      t.timestamps
    end
    # Each of these are likely to be searched on frequently
    add_index :entitlements, :object_id
    add_index :entitlements, :object_type
    add_index :entitlements, %i[object_id object_type], unique: false
    add_index :entitlements, :flag
    add_index :entitlements, %i[flag data], unique: false
    add_index :entitlements, %i[object_id object_type flag data]
  end
end
