class AddUniquenessConstraintToTags < ActiveRecord::Migration[7.2]
  def up
    add_column :tags, :lower, :string, limit: 254, null: true

    Tag.destroy_all
    change_column_null :tags, :lower, false

    add_index :tags, [:lower, :tag_type, :polarity], unique: true
  end

  def down
    remove_column :tags, :lower
  end
end
