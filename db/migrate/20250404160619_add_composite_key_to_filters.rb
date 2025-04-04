class AddCompositeKeyToFilters < ActiveRecord::Migration[7.2]
  def change
    remove_index :filters, [:target_type, :target_id, :group, :user_id, :filter_type]
    add_index :filters, [:target_type, :target_id, :group, :user_id, :filter_type], unique: true
  end
end
