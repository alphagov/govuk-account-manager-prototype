class AddSubjectIdentifierToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :subject_identifier, :string
  end
end
