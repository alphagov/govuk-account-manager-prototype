class DeduplicateLoginActivities < ActiveRecord::Migration[6.0]
  def up
    User.find_each do |user|
      activities = user.security_activities.where(event_type: "login").order(created_at: :desc)

      last_activity = nil
      activities.map do |activity|
        if last_activity.nil? || !very_similar_to(activity, last_activity)
          last_activity = activity
        else
          activity.destroy!
        end
      end
    end
  end

  def very_similar_to(activity1, activity2)
    return false unless activity1.event_type == activity2.event_type
    return false unless activity1.user_id == activity2.user_id
    return false unless activity1.ip_address == activity2.ip_address
    return false unless activity1.oauth_application_id == activity2.oauth_application_id

    a_minute_ago = activity1.created_at.to_i - 60
    a_minute_hence = activity1.created_at.to_i + 60
    (a_minute_ago..a_minute_hence).include? activity2.created_at.to_i
  end
end
