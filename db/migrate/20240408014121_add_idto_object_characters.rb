class AddIdtoObjectCharacters < ActiveRecord::Migration[7.0]
  def change
    add_column :object_characters, :id, :primary_key
  end
end
