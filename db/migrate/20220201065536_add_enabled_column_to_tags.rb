class AddEnabledColumnToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :enabled, :boolean, default: true, null: false
  end
end
