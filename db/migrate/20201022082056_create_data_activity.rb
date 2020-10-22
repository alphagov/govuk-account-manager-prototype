class CreateDataActivity < ActiveRecord::Migration[6.0]
  def change
    create_table :data_activities do |t|
      t.references :user,              null: false
      t.references :oauth_application, null: false
      t.string     :token,             null: false
      t.string     :scopes,            null: false

      t.timestamps null: false
    end

    add_foreign_key :data_activities, :users, column: :user_id
    add_foreign_key :data_activities, :oauth_applications, column: :oauth_application_id
  end
end
