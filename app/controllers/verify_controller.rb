class VerifyController < ApplicationController
  def show
    user_id = params.fetch(:user_id)
    token = params.fetch(:token)

    user = Services.keycloak.users.get(user_id)
    @state = EmailConfirmation.check_and_verify(user, token)
  rescue KeyError
    @state = :bad_parameters
  end
end
