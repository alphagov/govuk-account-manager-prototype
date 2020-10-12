class CreateEmailSubscription < ActiveRecord::Migration[6.0]
  def change
    create_table :email_subscriptions do |t|
      t.references :user,       null: false
      t.string     :topic_slug, null: false
      t.string     :subscription_id
    end

    add_foreign_key :email_subscriptions, :users, column: :user_id
  end
end
