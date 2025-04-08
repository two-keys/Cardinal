class AddDescriptionsToTags < ActiveRecord::Migration[7.2]
  def change
    add_column :tags, :tooltip, :string
    add_column :tags, :details, :text
  end
end
