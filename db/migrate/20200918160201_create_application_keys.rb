class CreateApplicationKeys < ActiveRecord::Migration[6.0]
  def change
    create_table :application_keys, primary_key: %i[application_uid key_id] do |t|
      t.string :application_uid
      t.uuid :key_id
      t.string :pem, null: false
      t.index :application_uid
    end
  end
end
