class ExpireRegistrationStateJob < ApplicationJob
  queue_as :default

  def perform
    RegistrationState.expired.delete_all
  end
end
