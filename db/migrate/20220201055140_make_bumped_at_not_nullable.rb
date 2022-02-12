class MakeBumpedAtNotNullable < ActiveRecord::Migration[7.0]
  def change
    change_column :prompts, :bumped_at, :datetime, precision: 6, null: false
  end
end
