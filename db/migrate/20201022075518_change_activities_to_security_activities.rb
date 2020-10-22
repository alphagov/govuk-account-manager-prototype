class ChangeActivitiesToSecurityActivities < ActiveRecord::Migration[6.0]
  def change
    rename_table :activities, :security_activities
  end
end
