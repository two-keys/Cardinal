class CreateThemes < ActiveRecord::Migration[7.2]
  def change
    create_table :themes do |t|
      t.string :title, null: false
      t.boolean :public, null: false, default: false
      t.boolean :system, null: false, default: false
      t.text :css, null: false, default: ""
      t.references :user, foreign_key: true

      t.timestamps
    end
    add_index :themes, :public
    add_index :themes, :system
  end
end
