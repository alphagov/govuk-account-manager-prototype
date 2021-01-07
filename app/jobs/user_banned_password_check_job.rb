class UserBannedPasswordCheckJob < ApplicationJob
  queue_as :user_password_check

  BATCH_SIZE = 10

  def perform(user_id, offset = 0)
    user = User.find(user_id)
    denylist = BannedPassword.limit(BATCH_SIZE).offset(offset).pluck(:password)

    has_banned_password = denylist.any? do |password| # pragma: allowlist secret
      user.valid_password?(password)
    end

    if denylist.length < BATCH_SIZE || has_banned_password
      user.update!(banned_password_match: has_banned_password)
    else
      UserBannedPasswordCheckJob.perform_later(user_id, offset + BATCH_SIZE)
    end
  end
end
