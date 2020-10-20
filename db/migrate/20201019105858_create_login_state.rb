class CreateLoginState < ActiveRecord::Migration[6.0]
  def change
    create_table :login_states, id: :uuid do |t|
      t.datetime   :created_at,    null: false
      t.references :user,          null: false
      t.string     :redirect_path, null: false
    end

    add_foreign_key :login_states, :users, column: :user_id
  end
end
