class FixFiltersUniquenessConstraint < ActiveRecord::Migration[7.2]
  def change
    remove_index :filters, name: 'index_filters_on_target_type_and_target_id_and_group'
    add_index :filters, [:target_type, :target_id, :group, :user_id], unique: true
  end
end
