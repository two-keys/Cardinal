class CreateAds < ActiveRecord::Migration[7.2]
  def change
    create_table :ads do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :variant, null: false, default: 0
      t.string :url
      t.integer :impressions, null: false, default: 0
      t.integer :clicks, null: false, default: 0

      t.timestamps
    end
  end
end
