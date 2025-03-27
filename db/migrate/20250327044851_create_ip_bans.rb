class CreateIpBans < ActiveRecord::Migration[7.2]
  def change
    create_table :ip_bans do |t|
      t.string :title
      t.text :context
      t.inet :addr, null: false
      t.datetime :expires_on

      t.timestamps
    end
    add_index :ip_bans, :addr, unique: true
  end
end
