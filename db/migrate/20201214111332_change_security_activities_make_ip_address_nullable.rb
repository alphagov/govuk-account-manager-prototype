class ChangeSecurityActivitiesMakeIpAddressNullable < ActiveRecord::Migration[6.0]
  def change
    change_column_null :security_activities, :ip_address, true
  end
end
