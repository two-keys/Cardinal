class AddAncestryToTags < ActiveRecord::Migration[7.0]
  def change
    remove_reference :tags, :parent, foreign_key: { to_table: :tags }, index: false

    add_column :tags, :ancestry, :string
    add_index :tags, :ancestry, using: 'btree', opclass: :text_pattern_ops
  end
end
