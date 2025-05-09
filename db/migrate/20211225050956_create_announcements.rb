# frozen_string_literal: true

class CreateAnnouncements < ActiveRecord::Migration[7.0]
  def change
    create_table :announcements do |t|
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
