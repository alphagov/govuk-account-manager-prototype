class AddPasswordOkToLoginState < ActiveRecord::Migration[6.0]
  def change
    add_column :login_states, :password_ok, :boolean, default: false, null: false
  end
end
