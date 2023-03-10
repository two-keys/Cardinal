class FixObjectIndexOnObjectTags < ActiveRecord::Migration[7.0]
  def change
    remove_index :object_tags, name: :index_object_tags_on_object 
    add_index :object_tags, [:object_type, :object_id, :tag_id], unique: true
  end
end
