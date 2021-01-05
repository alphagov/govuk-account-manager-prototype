class AddBannedPasswordMatchToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :banned_password_match, :boolean
  end
end
