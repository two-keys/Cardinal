class AddPolymorphicFieldToObjectTags < ActiveRecord::Migration[7.0]
  def change
    remove_reference :object_tags, :prompt, index: true, foreign_key: true

    add_reference :object_tags, :object, polymorphic: true, index: { unique: true }
  end
end
