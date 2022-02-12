class AddBumpedAtToPrompts < ActiveRecord::Migration[7.0]
  def change
    add_column :prompts, :bumped_at, :datetime, precision: 6
  end
end
