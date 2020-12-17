class CreateBannedPassword < ActiveRecord::Migration[6.0]
  def change
    create_table :banned_passwords do |t|
      t.string :password, null: false
    end

    add_index :banned_passwords, :password, unique: true
  end
end
