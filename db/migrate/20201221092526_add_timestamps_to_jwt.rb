class AddTimestampsToJwt < ActiveRecord::Migration[6.0]
  def up
    add_timestamps :jwts
    Jwt.update_all(created_at: Time.zone.now, updated_at: Time.zone.now)
    change_column_null :jwts, :created_at, false
    change_column_null :jwts, :updated_at, false
  end

  def down
    remove_timestamps :jwts
  end
end
