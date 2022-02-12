class MakeTagNameColumnBigger < ActiveRecord::Migration[7.0]
  def change
    change_column :tags, :name, :string, limit: 254, null: false
  end
end
