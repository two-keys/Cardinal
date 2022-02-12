class CreatePromptTagsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :prompt_tags, id: false do |t|
      t.belongs_to :prompt, index: true, foreign_key: true
      t.belongs_to :tag, index: true, foreign_key: true
    end

    add_index :prompt_tags, [:prompt_id, :tag_id], unique: true
  end
end
