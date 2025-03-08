class AddThemeToUser < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :theme, foreign_key: true, null: true
  end
end
