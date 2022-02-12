class ReplaceTagsUniqueIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :tags, name: 'index_tags_on_name_and_tag_type'
    add_index :tags, [:name, :tag_type, :polarity], unique: true
  end
end
