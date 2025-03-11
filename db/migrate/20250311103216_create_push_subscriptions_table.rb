# frozen_string_literal: true

class CreatePushSubscriptionsTable < ActiveRecord::Migration[7.2]
  def change
    create_table :push_subscriptions, force: :cascade do |t|
      t.references :user, null: false, index: true
      t.string :endpoint
      t.string :p256dh_key
      t.string :auth_key
      t.timestamps

      t.string :user_agent
    end
  end
end
