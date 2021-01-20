class ExpireRegistrationStateJob < ApplicationJob
  queue_as :default

  def perform
    RegistrationState.where("updated_at < ?", 60.minutes.ago).delete_all
  end
end
