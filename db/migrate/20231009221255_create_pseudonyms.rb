class CreatePseudonyms < ActiveRecord::Migration[7.0]
  def change
    create_table :pseudonyms do |t|
      t.string :name, null: false, unique: true
      t.integer :status, default: 0, null: false

      t.belongs_to :user, index: true, foreign_key: true
      t.timestamps
    end
  end  
end
