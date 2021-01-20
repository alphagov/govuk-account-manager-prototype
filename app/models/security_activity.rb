require "geocoder"

class SecurityActivity < ApplicationRecord
  EVENTS = [
    # logging in
    ACCOUNT_LOCKED = LogEntry.new(id: 5, name: :account_locked, require_user: true),
    MANUAL_ACCOUNT_UNLOCK = LogEntry.new(id: 6, name: :manual_account_unlock, require_user: true),

    ADDITIONAL_FACTOR_VERIFICATION_SUCCESS = LogEntry.new(id: 7, name: :additional_factor_verification_success, require_user: true, require_factor: true),
    ADDITIONAL_FACTOR_VERIFICATION_FAILURE = LogEntry.new(id: 8, name: :additional_factor_verification_failure, require_user: true, require_factor: true),
    ADDITIONAL_FACTOR_BYPASS_USED = LogEntry.new(id: 13, name: :additional_factor_bypass_used, require_user: true),
    ADDITIONAL_FACTOR_BYPASS_GENERATED = LogEntry.new(id: 14, name: :additional_factor_bypass_generated, require_user: true),

    LOGIN_SUCCESS = LogEntry.new(id: 0, name: :login_success, require_user: true),
    LOGIN_FAILURE = LogEntry.new(id: 9, name: :login_failure, require_user: true),

    # recovery
    PASSWORD_RESET_REQUEST = LogEntry.new(id: 10, name: :password_reset_request, require_user: true),
    PASSWORD_RESET_SUCCESS = LogEntry.new(id: 4, name: :password_reset_success, require_user: true),

    # update
    EMAIL_CHANGE_REQUESTED = LogEntry.new(id: 1, name: :email_change_requested, require_user: true),
    EMAIL_CHANGED = LogEntry.new(id: 11, name: :email_changed, require_user: true),
    PHONE_CHANGED = LogEntry.new(id: 2, name: :phone_changed, require_user: true),
    PASSWORD_CHANGED = LogEntry.new(id: 3, name: :password_changed, require_user: true),

    # on create
    USER_CREATED = LogEntry.new(id: 12, name: :user_created, require_user: true),
  ].freeze

  EVENTS_REQUIRING_USER = EVENTS.select(&:require_user?)
  EVENTS_REQUIRING_APPLICATION = EVENTS.select(&:require_application?)
  EVENTS_REQUIRING_FACTOR = EVENTS.select(&:require_factor?)

  VALID_OPTIONS = %i[user user_id oauth_application oauth_application_id ip_address ip_address_country user_agent user_agent_id factor notes analytics].freeze

  VALID_FACTORS = %w[sms].freeze

  scope :show_on_security_page, -> { where(event_type: EVENTS.select { |e| I18n.exists?("account.security.event.#{e.name}") }.map(&:id)) }

  validates :user_id, presence: { if: proc { |event_log| EVENTS_REQUIRING_USER.include? event_log.event } }
  validates :oauth_application_id, presence: { if: proc { |event_log| EVENTS_REQUIRING_APPLICATION.include? event_log.event } }
  validates :factor, presence: { if: proc { |event_log| EVENTS_REQUIRING_FACTOR.include? event_log.event } }

  # account locking is done in the model, not the controller, so it
  # doesn't have access to the request env: no ip address, no user
  # agent.
  validates :ip_address, presence: { if: proc { |event_log| event_log.event != ACCOUNT_LOCKED } }

  validates :event_type, presence: true
  validate :validate_event_mappable
  validate :validate_factor

  belongs_to :user, optional: true
  belongs_to :oauth_application, class_name: "Doorkeeper::Application", optional: true
  belongs_to :user_agent, optional: true

  delegate :name, to: :event

  paginates_per 10

  def self.record_event(event, options = {})
    attributes = {
      event_type: event.id,
    }.merge(options.slice(*VALID_OPTIONS))

    if options[:user_agent_name]
      attributes.merge!(user_agent_id: UserAgent.find_or_create_by!(name: options[:user_agent_name]).id)
    end

    if attributes[:ip_address] && !attributes[:ip_address_country]
      attributes[:ip_address_country] = ip_to_country(attributes[:ip_address])
    end

    event = SecurityActivity.create!(attributes)
    event.log
    event
  end

  def self.ip_to_country(ip_address)
    Rails.cache.fetch("security_activities/ip_address/#{ip_address}", expires_in: 1.day) do
      Geocoder.search(ip_address)&.first&.country
    end
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

  def log
    # our rails logs are sent to splunk
    Rails.logger.public_send Rails.application.config.log_level, to_hash.to_json
  end

  def to_hash
    {
      id: id,
      timestamp: created_at.utc,
      action: event.name,
      user_id: user&.id,
      oauth_application_id: oauth_application&.id,
      oauth_application_name: oauth_application&.name,
      ip_address: ip_address,
      user_agent: user_agent&.name,
      factor: factor,
    }.compact
  end

  def fill_missing_country
    if ip_address_country.nil?
      update!(ip_address_country: SecurityActivity.ip_to_country(ip_address))
    end

    self
  end

protected

  def validate_event_mappable
    unless event
      errors.add(:event_type, "must have a corresponding `LogEntry` for #{event_type}")
    end
  end

  def validate_factor
    if factor && !VALID_FACTORS.include?(factor)
      errors.add(:factor, "must be one of nil or #{VALID_FACTORS.join(', ')}; not #{factor}")
    end
  end
end
