class SecurityActivity < ApplicationRecord
  # TODO: decide which of these to show on the security page
  EVENTS = [
    # logging in
    ACCOUNT_LOCKED = LogEntry.new(id: 5, name: :account_locked, require_user: true),
    MANUAL_ACCOUNT_UNLOCK = LogEntry.new(id: 6, name: :manual_account_unlock, require_user: true),

    ADDITIONAL_FACTOR_VERIFICATION_SUCCESS = LogEntry.new(id: 7, name: :additional_factor_verification_success, require_user: true),
    ADDITIONAL_FACTOR_VERIFICATION_FAILURE = LogEntry.new(id: 8, name: :additional_factor_verification_failure, require_user: true),

    LOGIN_SUCCESS = LogEntry.new(id: 0, name: :login_success, require_user: true),
    LOGIN_FAILURE = LogEntry.new(id: 9, name: :login_failure, require_user: true),

    # recovery
    PASSWORD_RESET_REQUEST = LogEntry.new(id: 10, name: :password_reset_request, require_user: true),
    PASSWORD_RESET_SUCCESS = LogEntry.new(id: 4, name: :password_reset_success, require_user: true),

    # update
    EMAIL_CHANGE_REQUESTED = LogEntry.new(id: 11, name: :email_change_requested, require_user: true),
    EMAIL_CHANGED = LogEntry.new(id: 1, name: :email_changed, require_user: true),
    PHONE_CHANGED = LogEntry.new(id: 2, name: :phone_changed, require_user: true),
    PASSWORD_CHANGED = LogEntry.new(id: 3, name: :password_changed, require_user: true),
  ].freeze

  EVENTS_REQUIRING_USER = EVENTS.select(&:require_user?)
  EVENTS_REQUIRING_APPLICATION = EVENTS.select(&:require_application?)

  VALID_OPTIONS = %i[user user_id oauth_application oauth_application_id ip_address user_agent user_agent_id].freeze

  validates :user_id, presence: { if: proc { |event_log| EVENTS_REQUIRING_USER.include? event_log.event } }
  validates :oauth_application_id, presence: { if: proc { |event_log| EVENTS_REQUIRING_APPLICATION.include? event_log.event } }

  # account locking is done in the model, not the controller, so it
  # doesn't have access to the request env: no ip address, no user
  # agent.
  validates :ip_address, presence: { if: proc { |event_log| event_log.event != ACCOUNT_LOCKED } }

  validates :event_type, presence: true
  validate :validate_event_mappable

  belongs_to :user, optional: true
  belongs_to :oauth_application, class_name: "Doorkeeper::Application", optional: true
  belongs_to :user_agent, optional: true

  delegate :name, to: :event

  def self.record_event(event, options = {})
    attributes = {
      event_type: event.id,
    }.merge(options.slice(*VALID_OPTIONS))

    if options[:user_agent_name]
      attributes.merge!(user_agent_id: UserAgent.find_or_create_by!(name: options[:user_agent_name]).id)
    end

    SecurityActivity.create!(attributes)
  end

  def self.of_type(event)
    where(event_type: event.id)
  end

  def event
    EVENTS.detect { |event| event.id == event_type }
  end

  def client
    if oauth_application_id.nil?
      AccountManagerApplication::NAME
    else
      Doorkeeper::Application.find(oauth_application_id).name
    end
  end

protected

  def validate_event_mappable
    unless event
      errors.add(:event_type, "must have a corresponding `LogEntry` for #{event_type}")
    end
  end
end
