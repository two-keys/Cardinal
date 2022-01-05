class AddIconToMessage < ActiveRecord::Migration[7.0]
  def change
    change_table :messages do |t|
      t.column :icon, :string
    end
  end
end
