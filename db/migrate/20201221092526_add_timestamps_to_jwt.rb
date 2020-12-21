class AddTimestampsToJwt < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :jwts, default: Time.zone.now
    change_column_default :jwts, :created_at, nil
    change_column_default :jwts, :updated_at, nil
  end
end
