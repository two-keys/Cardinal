class CreatePrompts < ActiveRecord::Migration[7.0]
  def change
    create_table :prompts do |t|
      t.belongs_to :user, index: true

      t.text :starter
      t.text :ooc

      t.timestamps
      t.integer :status, null: false, default: 0 # 0: draft, 1: locked, 2: posted
    end
  end
end
