class AddHasReceivedDowntimeEmailToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :has_received_downtime_email, :boolean, default: false, null: false
  end
end
