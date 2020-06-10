class VerifyController < ApplicationController
  def show
    @user_id = params.fetch(:user_id)
    token = params.fetch(:token)

    user = Services.keycloak.users.get(@user_id)
    @state = EmailConfirmation.check_and_verify(user, token)
  rescue KeyError
    @state = :bad_parameters
  end

  def send_new_link
    user_id = params.fetch(:user_id)
    user = Services.keycloak.users.get(user_id)
    @email = user.email
    EmailConfirmation.send(user)
    @state = :ok
  rescue KeyError
    @state = :no_such_user
  end
end
