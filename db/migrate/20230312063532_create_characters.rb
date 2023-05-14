class CreateCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :characters do |t|
      t.string :name
      t.text :description
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_reference :characters, :user, index: true, foreign_key: true
  end
end
