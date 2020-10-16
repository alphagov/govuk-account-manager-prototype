class CreateRegistrationState < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'

    create_table :registration_states, id: :uuid do |t|
      t.datetime :touched_at, null: false
      t.integer  :state,      null: false
      t.string   :email,      null: false
      t.string   :previous_url
      t.string   :password
      t.boolean  :yes_to_emails
      t.jsonb    :jwt_payload
    end
  end
end
