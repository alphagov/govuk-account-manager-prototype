class ExpireLoginStateJob < ApplicationJob
  queue_as :default

  def perform
    LoginState.expired.delete_all
  end
end
