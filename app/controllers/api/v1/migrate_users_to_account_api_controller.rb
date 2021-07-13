class Api::V1::MigrateUsersToAccountApiController < Doorkeeper::ApplicationController
  PAGE_SIZE = 100

  before_action -> { doorkeeper_authorize! :migrate_users }

  respond_to :json

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  def process_batch
    page = params.fetch(:page).to_i

    batch = User.order(created_at: :asc).page(page).per(PAGE_SIZE)

    render json: {
      users: migrate_batch_of_users(batch),
      is_last_page: batch.last_page?,
    }
  end

private

  def migrate_batch_of_users(batch)
    batch.map do |user|
      subject_identifier = Doorkeeper::OpenidConnect.configuration.subject.call(user, account_api).to_s
      remote_user_info = RemoteUserInfo.call(user)
      subscription = user.email_subscriptions.first

      subscription.update!(migrated_to_account_api: true) if subscription

      {
        subject_identifier: subject_identifier,
        transition_checker_state: remote_user_info[:transition_checker_state],
        topic_slug: subscription&.topic_slug,
        email_alert_api_subscription_id: subscription&.subscription_id,
      }
    end
  end

  def account_api
    @account_api ||= Doorkeeper::Application.find_by(uid: ENV.fetch("ACCOUNT_API_DOORKEEPER_UID"))
  end
end
