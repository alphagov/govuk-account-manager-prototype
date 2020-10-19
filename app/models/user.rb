class User < ApplicationRecord
  # any string with at least one digit in it
  PASSWORD_REGEX = /\A.*[0-9].*\z/.freeze

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  devise :database_authenticatable,
         :confirmable,
         :lockable,
         :recoverable,
         :registerable,
         :rememberable,
         :timeoutable,
         :trackable,
         :validatable

  validates :password, format: { with: PASSWORD_REGEX }, allow_blank: true

  has_many :access_grants,
           class_name: "Doorkeeper::AccessGrant",
           foreign_key: :resource_owner_id,
           dependent: :destroy

  has_many :access_tokens,
           class_name: "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent: :destroy

  has_many :activities,
           dependent: :destroy

  has_many :email_subscriptions,
           dependent: :destroy

  after_commit :update_remote_user_info, on: %i[create update]

  # this has to happen before the record is actually destroyed because
  # there's a foreign key constraint ensuring that an access token
  # corresponds to a user.
  #
  # the prepend: true is a concession to testing, it's so we can
  # confirm the right access token is being used (otherwise the access
  # token gets destroyed between the test reading it and this callback
  # happening)
  before_destroy :destroy_remote_user_info_immediately, prepend: true

  def update_tracked_fields!(request)
    super(request)
    Activity.login!(self, request.remote_ip) unless new_record?
  end

  def update_remote_user_info
    UpdateRemoteUserInfoJob.perform_later id
  end

  def destroy_remote_user_info_immediately
    RemoteUserInfo.new(self).destroy!
  end

  # from devise
  def after_confirmation
    ActivateEmailSubscriptionsJob.perform_later id
  end

  def needs_mfa?
    !phone.nil?
  end
end
