class ExpireLoginStateJob < ApplicationJob
  queue_as :default

  def perform
    LoginState.where("created_at < ?", 60.minutes.ago).delete_all
  end
end
