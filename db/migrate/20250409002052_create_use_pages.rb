class CreateUsePages < ActiveRecord::Migration[7.2]
  def up
    create_table :use_pages do |t|
      t.string :title, null: false
      t.text :content
      t.integer :order, null: false, default: 0

      t.timestamps
    end
    add_index :use_pages, [:title], unique: true

    CardinalSettings::Use.pages.keys.each do |page|
      entries = CardinalSettings::Use.get_page(page)['entries'] || []
      joined_entries = entries.join("\n\n")
      UsePage.create(title: page, content: "#{CardinalSettings::Use.get_page(page)['markdown']}\n\n#{joined_entries}")
    end

    counter = 0
    UsePage.all.each do |page|
      page.update(order: counter)
      counter = counter + 1
    end


    index = UsePage.find_by(title: 'index')
    UsePage.create(title: 'index') unless index
  end
  def down
    remove_index :use_pages, [:title]
    drop_table :use_pages
  end
end
