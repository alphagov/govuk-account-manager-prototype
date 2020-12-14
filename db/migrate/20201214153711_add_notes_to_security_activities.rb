class AddNotesToSecurityActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :security_activities, :notes, :string
  end
end
