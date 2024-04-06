class CreateObjectCharacterJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_table :object_characters, id: false do |t|
      t.belongs_to :character, foreign_key: true
    end

    add_reference :object_characters, :object, polymorphic: true, index: { unique: false }
    add_index :object_characters, [:object_type, :object_id, :character_id], unique: true, name: "index_object_characters_with_id"
  end
end
