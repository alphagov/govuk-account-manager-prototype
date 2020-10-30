class AddOnboardingFlagToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :has_received_onboarding_email, :bool, null: false, default: false
  end
end
