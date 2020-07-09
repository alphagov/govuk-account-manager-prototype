class CreateActivities < ActiveRecord::Migration[6.0]
  def change
    create_table :activities do |t|
      t.integer    :event_type,        null: false
      t.references :user,              null: false
      t.string     :ip_address,        null: false
      t.references :oauth_application

      t.timestamps null: false
    end

    add_foreign_key :activities, :users, column: :user_id
    add_foreign_key :activities, :oauth_applications, column: :oauth_application_id
  end
end
