class AddIdToPromptTags < ActiveRecord::Migration[7.0]
  def change
    add_column :prompt_tags, :id, :primary_key
  end
end
