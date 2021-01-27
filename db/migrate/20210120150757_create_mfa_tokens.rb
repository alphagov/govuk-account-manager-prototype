class CreateMfaTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :mfa_tokens do |t|
      t.references :user,  null: false
      t.string     :token, null: false
      t.timestamps         null: false
    end

    add_foreign_key :mfa_tokens, :users, column: :user_id
  end
end
