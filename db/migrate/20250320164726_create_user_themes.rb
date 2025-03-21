class CreateUserThemes < ActiveRecord::Migration[7.2]
  def change
    create_table :user_themes do |t|
      t.boolean :enabled, null: false, default: false
      t.references :user, null: false, foreign_key: true
      t.references :theme, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_themes, :enabled

    User.all.each do |user|
      user.applied_themes << user.theme if user.theme
    end
    
    add_column :users, :themes_enabled, :boolean, null: false, default: false
  end
end
