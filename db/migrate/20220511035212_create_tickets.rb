class CreateTickets < ActiveRecord::Migration[7.0]
  def change
    create_table :tickets do |t|
      t.belongs_to :user, index: true, foreign_key: true

      t.column :created_at, :datetime, null: false
    end
    
    add_reference :tickets, :item, polymorphic: true, index: true, null: true
  end
end
