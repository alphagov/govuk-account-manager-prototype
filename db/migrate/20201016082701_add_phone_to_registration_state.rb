class AddPhoneToRegistrationState < ActiveRecord::Migration[6.0]
  def change
    add_column :registration_states, :phone, :string
    add_column :registration_states, :phone_code, :string
    add_column :registration_states, :phone_code_generated_at, :timestamp
    add_column :registration_states, :mfa_attempts, :integer
  end
end
