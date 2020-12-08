class ExpireEphemeralStateJob < ApplicationJob
  queue_as :default

  def perform
    EphemeralState.where("created_at < ?", 60.minutes.ago).delete_all
  end
end
