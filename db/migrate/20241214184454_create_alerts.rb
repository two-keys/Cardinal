class CreateAlerts < ActiveRecord::Migration[7.0]
  def change
    create_table :alerts do |t|
      t.string :title, null: false
      t.string :find, null: false
      t.boolean :regex, default: false
      t.string :replacement

      t.timestamps
    end
  end
end
