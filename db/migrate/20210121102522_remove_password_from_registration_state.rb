class RemovePasswordFromRegistrationState < ActiveRecord::Migration[6.0]
  def change
    remove_column :registration_states, :password, :string, default: false, null: false
  end
end
