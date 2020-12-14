class RemovePasswordOkFromLoginStates < ActiveRecord::Migration[6.0]
  def change
    remove_column :login_states, :password_ok, :boolean, default: false, null: false
  end
end
