class AddColorToPrompts < ActiveRecord::Migration[7.2]
  def change
    add_column :prompts, :color, :text, limit: 7, null: false, default: "#000000"
  end
end
