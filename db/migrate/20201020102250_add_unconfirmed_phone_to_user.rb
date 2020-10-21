class AddUnconfirmedPhoneToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :unconfirmed_phone, :string
  end
end
