class AddTimestampsToLoginState < ActiveRecord::Migration[6.0]
  def change
    # this to recreate the column with the default rails timestamp
    # settings, it's safe because the field never "disappears" (though
    # the migration does reset its value)
    remove_column :login_states, :created_at, default: -> { 'now()' }, null: false

    add_timestamps :login_states, default: -> { 'now()' }, null: false
  end
end
