class AddPolarityToPromptTags < ActiveRecord::Migration[7.0]
  def change
    add_column :prompt_tags, :polarity, :string, limit: 25
  end
end
