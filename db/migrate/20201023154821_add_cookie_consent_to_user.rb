class AddCookieConsentToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :cookie_consent, :boolean, null: false, default: false
  end
end
