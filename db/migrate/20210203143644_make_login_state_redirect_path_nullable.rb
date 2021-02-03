class MakeLoginStateRedirectPathNullable < ActiveRecord::Migration[6.0]
  def up
    change_column_null :login_states, :redirect_path, true
  end

  def down
    LoginState.where(redirect_path: nil).update_all(redirect_path: "/account")
    change_column_null :login_states, :redirect_path, false
  end
end
