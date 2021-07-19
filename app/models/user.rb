class User < ApplicationRecord
  attr_accessor :enforce_has_mfa

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  devise :database_authenticatable,
         :confirmable,
         :lockable,
         :recoverable,
         :registerable,
         :timeoutable,
         :trackable,
         :validatable

  has_many :access_grants,
           class_name: "Doorkeeper::AccessGrant",
           foreign_key: :resource_owner_id,
           dependent: :destroy

  has_many :access_tokens,
           class_name: "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent: :destroy

  has_many :data_activities,
           dependent: :destroy

  has_many :security_activities,
           dependent: :destroy

  has_many :email_subscriptions,
           dependent: :destroy

  # these may hang around if a login attempt is abandoned
  has_many :login_states,
           dependent: :destroy

  has_many :ephemeral_states,
           dependent: :destroy

  has_many :mfa_tokens,
           dependent: :destroy

  validate :password_cannot_be_on_denylist, if: :password_required?
  validate :validate_phone_number, if: -> { enforce_has_mfa || phone.present? }

  # this has to happen before the record is actually destroyed because
  # there's a foreign key constraint ensuring that an access token
  # corresponds to a user.
  #
  # the prepend: true is a concession to testing, it's so we can
  # confirm the right access token is being used (otherwise the access
  # token gets destroyed between the test reading it and this callback
  # happening)
  before_destroy :destroy_remote_user_info_immediately, prepend: true

  before_save :format_phone_number

  def update_remote_user_info
    UpdateRemoteUserInfoJob.perform_later id
  end

  def destroy_remote_user_info_immediately
    RemoteUserInfo.new(self).destroy!
  end

  def after_confirmation
    if email_before_last_save != email
      UserMailer.with(old_address: email_before_last_save).change_email_from_email.deliver_later
    end
    if has_received_onboarding_email
      UserMailer.with(user: self).change_email_to_email.deliver_later
    else
      UserMailer.with(user: self).onboarding_email.deliver_later
      update!(has_received_onboarding_email: true)
    end
  end

  def lock_access!(opts = {})
    SecurityActivity.record_event(
      SecurityActivity::ACCOUNT_LOCKED,
      user: self,
    )

    super(opts)
  end

  def authenticatable_salt
    "#{super}#{session_token}"
  end

  def invalidate_all_sessions!
    update!(session_token: SecureRandom.hex)
  end

  def needs_mfa?
    !phone.nil?
  end

  def format_phone_number
    self.phone = MultiFactorAuth.e164_number(phone) if phone
  end

  def validate_phone_number
    if phone.blank?
      errors.add :phone, :blank
    elsif !MultiFactorAuth.valid?(phone)
      errors.add :phone, :invalid
    end
  end

  def password_cannot_be_on_denylist
    if BannedPassword.is_password_banned? password
      errors.add :password, :denylist
    end
  end
end
