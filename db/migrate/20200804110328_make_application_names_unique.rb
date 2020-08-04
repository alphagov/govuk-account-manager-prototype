class MakeApplicationNamesUnique < ActiveRecord::Migration[6.0]
  def change
    add_index :oauth_applications, :name, unique: true
  end
end
