class AddPseudonymToObjects < ActiveRecord::Migration[7.0]
  def change
    add_reference :prompts, :pseudonym, index: true, null: true, foreign_key: true
    add_reference :characters, :pseudonym, index: true, null: true, foreign_key: true
    add_reference :chat_users, :pseudonym, index: true, null: true, foreign_key: true
  end
end
