class AddLevelOfAuthenticationToEphemeralState < ActiveRecord::Migration[6.0]
  def change
    add_column :ephemeral_states, :level_of_authentication, :string, default: "level0", null: false
  end
end
