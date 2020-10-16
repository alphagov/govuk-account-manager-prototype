class DeviseRegistrationController < Devise::RegistrationsController
  # rubocop:disable Rails/LexicallyScopedActionFilter
  prepend_before_action :authenticate_scope!, only: %i[edit_password edit_email update destroy]
  prepend_before_action :set_minimum_password_length, only: %i[new edit_password edit_email]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  before_action :check_registration_state, only: %i[
    your_information
    your_information_post
    transition_emails
    transition_emails_post
    create
  ]

  def start
    @registration_state_id = params[:registration_state_id]
    # if this is unset we've been sent here from the welcome form
    unless @registration_state_id
      redirect_to new_user_session_path and return unless params.dig(:user, :email)

      jwt_payload = ApplicationKey.validate_jwt!(params[:jwt]) if params[:jwt]

      @registration_state = RegistrationState.create!(
        touched_at: Time.zone.now,
        state: :start,
        email: params[:user][:email],
        previous_url: params[:previous_url],
        jwt_payload: jwt_payload,
      )
      @registration_state_id = registration_state.id
    end

    redirect_to url_for_state and return unless registration_state.state == "start"

    password = params.dig(:user, :password) # pragma: allowlist secret
    password_confirmation = params.dig(:user, :password_confirmation)
    password_format_ok = User::PASSWORD_REGEX.match? password
    password_length_ok = Devise.password_length.include? password&.length
    password_confirmation_ok = password == password_confirmation

    if password_format_ok && password_length_ok && password_confirmation_ok
      registration_state.update!(
        state: :your_information,
        password: password,
      )
      redirect_to new_user_registration_your_information_path(registration_state_id: @registration_state_id)
    else
      @resource_error_messages = {
        password: [ # pragma: allowlist secret
          password_format_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password.invalid"),
          password_length_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password.too_short"),
        ],
        password_confirmation: [
          password_confirmation_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"),
        ],
      }
    end
  end

  def your_information
    redirect_to url_for_state unless registration_state.state == "your_information"
  end

  def your_information_post
    redirect_to url_for_state unless registration_state.state == "your_information"

    email_topic_slug = registration_state.jwt_payload&.dig("attributes", "transition_checker_state", "email_topic_slug")
    if email_topic_slug
      registration_state.update!(state: :transition_emails)
      redirect_to new_user_registration_transition_emails_path(registration_state_id: @registration_state_id)
    else
      redirect_to new_user_registration_finish_path(registration_state_id: @registration_state_id)
    end
  end

  def transition_emails
    redirect_to url_for_state unless registration_state.state == "transition_emails"
  end

  def transition_emails_post
    redirect_to url_for_state unless registration_state.state == "transition_emails"

    decision = params.dig(:email_decision)
    decision_format_ok = %w[yes no].include? decision
    if decision_format_ok
      registration_state.update!(
        state: :finish,
        yes_to_emails: decision == "yes",
      )
      redirect_to new_user_registration_finish_path(registration_state_id: @registration_state_id)
      return
    end

    @resource_error_messages = {
      email_decision: [
        I18n.t("activerecord.errors.models.user.attributes.email_decision.invalid"),
      ],
    }
    render :transition_emails
  end

  def create
    super do |resource|
      next unless resource.persisted?

      persist_attributes(resource)
      persist_email_subscription(resource)

      @previous_url = registration_state.previous_url
      registration_state.destroy!
    end
  end

  # from https://github.com/heartcombo/devise/blob/f5cc775a5feea51355036175994edbcb5e6af13c/app/controllers/devise/registrations_controller.rb#L46
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      # this is the change to the standard controller method:
      Activity.change_email_or_password!(
        resource,
        request.remote_ip,
      )
      # back to normal:

      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  def cancel
    registration_state&.destroy!
    super
  end

  def edit_email; end

  def edit_password; end

protected

  def after_update_path_for(_resource)
    confirmation_email_sent_path
  end

  def after_sign_up_path_for(resource)
    new_user_after_sign_up_path(previous_url: @previous_url, email: resource.email)
  end

  def after_inactive_sign_up_path_for(resource)
    new_user_after_sign_up_path(previous_url: @previous_url, email: resource.email)
  end

  def check_registration_state
    @registration_state_id = params[:registration_state_id]
    redirect_to new_user_session_path unless registration_state
  end

  # used in the 'super' of 'create'
  def respond_with(resource, *args, location: nil, **kwargs)
    if location
      redirect_to location
    else
      super(resource, *args, **kwargs)
    end
  end

  # used in the 'super' of 'create'
  def sign_up_params
    {
      email: registration_state.email,
      password: registration_state.password, # pragma: allowlist secret
      # we check this matches in 'start_post'
      password_confirmation: registration_state.password,
    }
  end

  def registration_state
    @registration_state ||=
      begin
        state = RegistrationState.find(@registration_state_id)
        state.update!(touched_at: Time.zone.now)
        state
      rescue ActiveRecord::RecordNotFound # rubocop:disable Lint/SuppressedException
      end
  end

  def url_for_state
    case registration_state.state
    when "your_information"
      new_user_registration_your_information_path(registration_state_id: @registration_state_id)
    when "transition_emails"
      new_user_registration_transition_emails_path(registration_state_id: @registration_state_id)
    when "finish"
      new_user_registration_finish_path(registration_state_id: @registration_state_id)
    else
      new_user_session_path
    end
  end

  def persist_attributes(user)
    return unless registration_state.jwt_payload
    return if registration_state.jwt_payload["scopes"].empty?

    token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      application_id: registration_state.jwt_payload["application"]["id"],
      expires_in: Doorkeeper.config.access_token_expires_in,
      scopes: registration_state.jwt_payload["scopes"],
    )

    SetAttributesJob.perform_later(token.id, registration_state.jwt_payload["attributes"])
  end

  def persist_email_subscription(user)
    return unless registration_state.jwt_payload
    return unless registration_state.yes_to_emails

    email_topic_slug = registration_state.jwt_payload.dig("attributes", "transition_checker_state", "email_topic_slug")
    return unless email_topic_slug

    EmailSubscription.create!(user_id: user.id, topic_slug: email_topic_slug)
  end
end
