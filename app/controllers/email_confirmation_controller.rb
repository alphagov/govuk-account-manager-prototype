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

  def resend_confirmation
    @email = params.fetch(:email)
    user = Services.keycloak.users.search(@email).first
    EmailConfirmation.send(user)
    @state = :ok
  rescue KeyError
    @state = :no_such_user
  end
end
