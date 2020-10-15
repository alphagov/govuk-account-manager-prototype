class DeviseRegistrationController < Devise::RegistrationsController
  def create
    head 422 and return unless params[:user][:email]

    payload = ApplicationKey.validate_jwt!(params[:jwt]) if params[:jwt]

    state = RegistrationStateMachine.call(params, payload)
    @state = state[:state]
    @resource_error_messages = state[:resource_error_messages]

    # skip the devise logic because we're not yet done showing screens
    # to the user
    unless @state == :finish
      render :new
      return
    end

    unless payload
      super
      return
    end

    super do |resource|
      next unless resource.persisted?

      persist_attributes(resource, payload)
      persist_email_subscription(resource, payload)
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

protected

  def after_update_path_for(_resource)
    confirmation_email_sent_path
  end

  def after_sign_up_path_for(resource)
    new_user_after_sign_up_path(previous_url: params[:previous_url], email: resource.email)
  end

  def after_inactive_sign_up_path_for(resource)
    new_user_after_sign_up_path(previous_url: params[:previous_url], email: resource.email)
  end

  def persist_attributes(user, jwt_payload)
    return if jwt_payload[:scopes].empty?

    token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      application_id: jwt_payload[:application].id,
      expires_in: Doorkeeper.config.access_token_expires_in,
      scopes: jwt_payload[:scopes],
    )

    SetAttributesJob.perform_later(token.id, jwt_payload[:attributes])
  end

  def persist_email_subscription(user, jwt_payload)
    email_decision = params[:email_decision]
    return unless email_decision == "yes"

    email_topic_slug = jwt_payload.dig(:attributes, :transition_checker_state, "email_topic_slug")
    return unless email_topic_slug

    EmailSubscription.create!(user_id: user.id, topic_slug: email_topic_slug)
  end
end
