class AddPolymorphicFieldToFilters < ActiveRecord::Migration[7.2]
  def change
    remove_reference :filters, :tag, index: true, foreign_key: true

    add_reference :filters, :target, polymorphic: true, index: { unique: false }
    add_index :filters, [:target_type, :target_id, :group], unique: true
  end
end
