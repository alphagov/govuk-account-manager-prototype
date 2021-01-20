class RemoveTouchedAtFromRegistrationState < ActiveRecord::Migration[6.0]
  def change
    remove_column :registration_states, :touched_at, default: -> { 'now()' }, null: false
  end
end
