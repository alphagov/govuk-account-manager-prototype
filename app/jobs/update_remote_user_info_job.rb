class UpdateRemoteUserInfoJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    RemoteUserInfo.new(User.find(user_id)).update_profile!
  end
end
