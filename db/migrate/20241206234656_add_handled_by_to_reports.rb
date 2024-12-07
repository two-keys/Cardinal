class AddHandledByToReports < ActiveRecord::Migration[7.0]
  def change
    add_reference :reports, :handled_by, index: true, null: true
    reversible do |change|
        change.up do
            first_admin = User.find_by(admin: true)
            Report.where(handled: true) do |item|
                item.handled_by = first_admin
                item.save
            end
        end
    end
    add_foreign_key :reports, :users, column: :handled_by_id
  end
end
