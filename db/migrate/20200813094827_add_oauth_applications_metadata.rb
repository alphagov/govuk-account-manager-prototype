class AddOauthApplicationsMetadata < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :contacts, :text, array: true, default: []
    add_column :oauth_applications, :logo_uri, :text
    add_column :oauth_applications, :client_uri, :text
    add_column :oauth_applications, :policy_uri, :text
  end
end
