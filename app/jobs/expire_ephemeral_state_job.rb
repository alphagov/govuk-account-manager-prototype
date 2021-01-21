class ExpireEphemeralStateJob < ApplicationJob
  queue_as :default

  def perform
    EphemeralState.expired.delete_all
  end
end
