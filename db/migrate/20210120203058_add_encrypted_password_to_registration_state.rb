class AddEncryptedPasswordToRegistrationState < ActiveRecord::Migration[6.0]
  def change
    add_column :registration_states, :encrypted_password, :string
    change_column_null :registration_states, :password, true
  end
end
