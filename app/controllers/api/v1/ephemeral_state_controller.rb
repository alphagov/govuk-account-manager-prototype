class Api::V1::EphemeralStateController < Doorkeeper::ApplicationController
  before_action :doorkeeper_authorize!

  def show
    ephemeral_state = EphemeralState.find_by(token: doorkeeper_token.token)

    unless ephemeral_state
      # if we're here the token is valid, so the EphemeralState did
      # exist once, but now it's gone - so a 410 is more appropriate
      # than a 404.
      head :gone
      return
    end

    out = ephemeral_state.to_hash
    ephemeral_state.destroy!
    render json: out
  end
end
