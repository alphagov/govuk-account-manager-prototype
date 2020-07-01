class EmailConfirmationController < ApplicationController
  def confirm_email
    user_id = params.fetch(:user_id)
    token = params.fetch(:token)

    user = Services.keycloak.users.get(user_id)
    @email = user.email
    @state = user.email_verified ? :already_verified : EmailConfirmation.check_and_verify(user, token)
    render "error" unless @state == :ok
  rescue KeyError
    @state = :bad_parameters
    render "error"
  end

  def cancel_change
    @user_id = params.fetch(:user_id)
    user = Services.keycloak.users.get(user_id)
    @state = EmailConfirmation.cancel_change(user)
    render "error" unless @state == :ok
  rescue KeyError
    @state = :bad_parameters
    render "error"
  end

  def resend_confirmation
    @email = params.fetch(:email)
    user = Services.keycloak.users.search(@email).first
    @state = EmailConfirmation.send(user) ? :ok : :no_such_user
  end
end
