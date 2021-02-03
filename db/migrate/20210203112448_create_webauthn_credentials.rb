class CreateWebauthnCredentials < ActiveRecord::Migration[6.0]
  def change
    create_table :webauthn_credentials do |t|
      t.string :external_id
      t.string :public_key
      t.string :nickname
      t.bigint :sign_count, null: false, default: 0
      t.references :user, foreign_key: true

      t.timestamps null: false
    end

    add_index :webauthn_credentials, :external_id, unique: true
  end
end
