class CreateJwt < ActiveRecord::Migration[6.0]
  def change
    create_table :jwts, id: :uuid do |t|
      t.jsonb "jwt_payload"
    end

    add_column :registration_states, :jwt_id, :uuid
    add_foreign_key :registration_states, :jwts, column: :jwt_id

    RegistrationState.all.each do |state|
      next unless state.read_attribute(:jwt_payload)
      jwt = Jwt.create(jwt_payload: state.read_attribute(:jwt_payload), skip_parse_jwt_token: true)
      RegistrationState.update(jwt_id: jwt.id)
    end

    remove_column :registration_states, :jwt_payload, :jsonb

    add_column :login_states, :jwt_id, :uuid
    add_foreign_key :login_states, :jwts, column: :jwt_id
  end
end
