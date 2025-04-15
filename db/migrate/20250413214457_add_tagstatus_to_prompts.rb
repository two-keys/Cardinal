class AddTagstatusToPrompts < ActiveRecord::Migration[7.2]
  def change
    add_column :prompts, :tag_status, :integer, null: false, default: 1
    add_index :prompts, :tag_status

    add_column :characters, :tag_status, :integer, null: false, default: 1
    add_index :characters, :tag_status
  end
end
