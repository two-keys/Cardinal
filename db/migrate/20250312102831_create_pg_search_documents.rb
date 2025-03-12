# frozen_string_literal: true

class CreatePgSearchDocuments < ActiveRecord::Migration[7.2]
  def up
    say_with_time('Creating table for pg_search multisearch') do
      create_table :pg_search_documents do |t|
        t.text :content
        t.belongs_to :user, index: true, null: true
        t.belongs_to :chat, index: true, null: true
        t.belongs_to :searchable, polymorphic: true, index: true
        t.timestamps null: false
      end
    end
    Message.rebuild_pg_search_documents
  end

  def down
    say_with_time('Dropping table for pg_search multisearch') do
      drop_table :pg_search_documents
    end
  end
end
