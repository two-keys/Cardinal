class CreateConnectCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :connect_codes do |t|
      t.belongs_to :user, foreign_key: true, null: false
      t.belongs_to :chat, foreign_key: true
      t.string :code
      t.integer :remaining_uses, default: 1

      t.timestamps
    end
  end
end
