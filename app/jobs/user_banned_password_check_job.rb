class UserBannedPasswordCheckJob < ApplicationJob
  queue_as :user_password_check

  def perform(user_id)
    user = User.find(user_id)

    has_banned_password = BannedPassword.pluck(:password).any? do |password|
      user.valid_password?(password)
    end

    user.update!(banned_password_match: has_banned_password)
  end
end
