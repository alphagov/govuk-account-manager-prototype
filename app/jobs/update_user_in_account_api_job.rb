class UpdateUserInAccountApiJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    application = Doorkeeper::Application.find_by(uid: ENV.fetch("ACCOUNT_API_DOORKEEPER_UID"))
    subject_identifier = Doorkeeper::OpenidConnect.configuration.subject.call(user, application).to_s

    GdsApi.account_api.update_user_by_subject_identifier(
      subject_identifier: subject_identifier,
      email: user.email,
      email_verified: user.confirmed?,
    )
  end
end
