class Api::V1::JwtController < Doorkeeper::ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :doorkeeper_authorize!

  respond_to :json

  def create
    head :bad_request and return if doorkeeper_token.resource_owner_id.present?

    jwt = Jwt.create!(
      jwt_payload: params.fetch(:jwt),
      application_id_from_token: doorkeeper_token.application_id,
    )

    render json: { id: jwt.id }
  end
end
