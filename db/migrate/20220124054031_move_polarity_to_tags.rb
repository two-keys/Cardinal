class MovePolarityToTags < ActiveRecord::Migration[7.0]
  def change
    remove_column :prompt_tags, :polarity, :string, limit: 25
    add_column :tags, :polarity, :string, limit: 25
  end
end
