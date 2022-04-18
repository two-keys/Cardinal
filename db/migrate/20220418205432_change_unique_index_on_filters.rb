class ChangeUniqueIndexOnFilters < ActiveRecord::Migration[7.0]
  def change
    remove_index :filters, [:user_id, :tag_id], unique: true

    add_index :filters, [:user_id, :tag_id, :group], unique: true
  end
end
