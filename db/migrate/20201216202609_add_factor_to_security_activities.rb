class AddFactorToSecurityActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :security_activities, :factor, :string
  end
end
