class AddVisibilityToMessages < ActiveRecord::Migration[7.2]
  def up
    add_column :messages, :visibility, :integer, null: false, default: 0
    add_index :messages, :visibility
    Message.update_all('
      visibility = CASE
        WHEN messages.ooc = true
          THEN 1
        ELSE
          0
        END
    ')
    remove_column :messages, :ooc
  end
  def down
    add_column :messages, :ooc, :boolean, default: false
    Message.update_all('
      ooc = CASE
        WHEN messages.visibility = 0
          THEN false
        ELSE
          true
        END
    ')
    remove_index :messages, :visibility
    remove_column :messages, :visibility
  end
end
