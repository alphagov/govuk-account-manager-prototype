class AddPhoneToRegistrationState < ActiveRecord::Migration[6.0]
  def change
    add_column :registration_states, :phone, :string
    add_column :registration_states, :phone_code, :string
  end
end
