class ExpireJwtJob < ApplicationJob
  queue_as :default

  def perform
    Jwt.without_login_states.without_registration_states.where("created_at < ?", 60.minutes.ago).delete_all
  end
end
