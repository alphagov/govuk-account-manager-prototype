class DataActivity < ApplicationRecord
  belongs_to :user

  belongs_to :oauth_application,
             class_name: "Doorkeeper::Application"

  def very_similar_to(other)
    return false unless user_id == other.user_id
    return false unless oauth_application_id == other.oauth_application_id

    a_minute_ago = created_at.to_i - 60
    a_minute_hence = created_at.to_i + 60
    (a_minute_ago..a_minute_hence).include? other.created_at.to_i
  end
end
