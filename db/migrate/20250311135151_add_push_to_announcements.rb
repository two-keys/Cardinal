# frozen_string_literal: true

class AddPushToAnnouncements < ActiveRecord::Migration[7.2]
  def change
    add_column :announcements, :push, :boolean, null: false, default: false
  end
end
