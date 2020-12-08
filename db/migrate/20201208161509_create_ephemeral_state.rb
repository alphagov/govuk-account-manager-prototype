class CreateEphemeralState < ActiveRecord::Migration[6.0]
  def change
    create_table :ephemeral_states do |t|
      t.references :user, null: false
      t.string :grant
      t.string :token
      t.string :ga_client_id

      t.timestamps null: false
    end

    add_foreign_key :ephemeral_states, :users, column: :user_id
  end
end
