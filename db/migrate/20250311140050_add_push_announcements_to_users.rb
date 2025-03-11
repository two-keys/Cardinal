# frozen_string_literal: true

class AddPushAnnouncementsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :push_announcements, :boolean, null: false, default: true
  end
end
