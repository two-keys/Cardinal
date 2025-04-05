class AddPriorityCompositeKeyToFilters < ActiveRecord::Migration[7.2]
  def change
    add_index :filters, [:target_type, :target_id, :filter_type, :group, :user_id, :priority]
  end
end
