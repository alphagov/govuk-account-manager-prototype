class AddTimestampsToRegistrationState < ActiveRecord::Migration[6.0]
  def change
    # this is so use of the field can be removed from the code without
    # error, after the new code is deployed a new migration to remove
    # the field will be made.
    change_column_null :registration_states, :touched_at, true

    add_timestamps :registration_states, default: -> { 'now()' }, null: false
  end
end
