class AddMigratedToAccountApiToSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :email_subscriptions, :migrated_to_account_api, :boolean, null: false, default: false
  end
end
