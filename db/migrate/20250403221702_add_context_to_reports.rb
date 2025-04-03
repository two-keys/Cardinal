class AddContextToReports < ActiveRecord::Migration[7.2]
  def change
    add_column :reports, :context, :string, null: false, default: "Unspecified"
  end
end
