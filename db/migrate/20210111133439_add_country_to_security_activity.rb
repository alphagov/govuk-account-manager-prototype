class AddCountryToSecurityActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :security_activities, :ip_address_country, :string
  end
end
