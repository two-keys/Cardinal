class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports do |t|
      t.boolean :handled, default: false
      t.integer :rules, null: false, array: true, default: []
      t.references :reporter, null: false
      t.references :reportee, null: false
      t.references :reportable, polymorphic: true, null: false

      t.timestamps
    end
    add_foreign_key :reports, :users, column: :reporter_id
    add_foreign_key :reports, :users, column: :reportee_id
  end
end
