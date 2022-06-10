class AddPostsCountToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :posts_count, :integer, :null => false, :default => 0
  end
end
