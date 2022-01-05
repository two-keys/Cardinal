class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.belongs_to :chat, index: true
      t.belongs_to :user, optional: true, index: true

      t.text :content, null: false
      t.boolean :ooc, default: false
      t.timestamps
    end
  end
end
