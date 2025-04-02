class AddMissingUniqueIndexes < ActiveRecord::Migration[7.2]
  def up
    add_index :pseudonyms, :name, unique: true

    remove_index :users, :email

    User.where(email: "").update_all(email: nil)
    
    add_index :users, :email, unique: true

    add_index :users, :username, unique: true
  end
  def down
    remove_index :pseudonmyms, :name

    remove_index :users, :email
    
    User.where(email: nil).update_all(email: "")

    add_index :users, :email, unique: false

    remove_index :users, :username
  end
end
