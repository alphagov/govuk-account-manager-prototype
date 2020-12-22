class AddAnalyticsToSecurityActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :security_activities, :analytics, :string
  end
end
