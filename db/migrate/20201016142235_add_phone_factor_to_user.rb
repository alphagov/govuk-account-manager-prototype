class AddPhoneFactorToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :phone_code, :string
    add_column :users, :phone_code_generated_at, :timestamp
    add_column :users, :mfa_attempts, :integer
    add_column :users, :last_mfa_success, :timestamp
  end
end
