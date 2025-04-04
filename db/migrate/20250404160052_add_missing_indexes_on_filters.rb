class AddMissingIndexesOnFilters < ActiveRecord::Migration[7.2]
  def change
    add_index :filters, [:target_type, :target_id, :group, :user_id, :filter_type]
    add_index :filters, :filter_type
  end
end
