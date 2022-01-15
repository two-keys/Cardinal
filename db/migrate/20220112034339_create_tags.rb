class CreateTags < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false, limit: 25
      t.string :tag_type, null: false, limit: 25
      t.belongs_to :synonym, null: true, foreign_key: { to_table: :tags } # ignore parent if this is set
      t.belongs_to :parent, null: true, foreign_key: { to_table: :tags }
    end

    add_index(:tags, [:name, :tag_type], unique: true)
  end
end
