class AddPriorityToUserThemes < ActiveRecord::Migration[7.2]
  def change
    add_column :user_themes, :priority, :integer, default: 0
  end
end
