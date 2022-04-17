class CreateFilters < ActiveRecord::Migration[7.0]
  def change
    create_table :filters do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :tag, index: true, foreign_key: true

      t.string :group, null: false, default: 'default'
      t.string :filter_type, null: false, limit: 25
      t.integer :priority, null: false, default: 0
    end

    add_index :filters, [:user_id, :tag_id], unique: true
  end
end
