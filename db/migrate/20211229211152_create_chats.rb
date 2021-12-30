class CreateChats < ActiveRecord::Migration[7.0]
  def change
    create_table :chats do |t|
      t.uuid :uuid, null: false, index: true, unique: true

      t.timestamps
    end
  end
end
