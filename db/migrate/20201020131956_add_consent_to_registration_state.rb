class AddConsentToRegistrationState < ActiveRecord::Migration[6.0]
  def change
    add_column :registration_states, :cookie_consent, :boolean
    add_column :registration_states, :feedback_consent, :boolean
  end
end
