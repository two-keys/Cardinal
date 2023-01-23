class RenamePromptTagToObjectTag < ActiveRecord::Migration[7.0]
  def change
    rename_table :prompt_tags, :object_tags
  end
end
