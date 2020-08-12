class ApiRegisterClientController < Doorkeeper::ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  respond_to :json

  rescue_from ActionController::ParameterMissing do
    head 400
  end

  def create
    return head 400 if params["subject_type"].present? && params["subject_type"] != "pairwise"

    client = Doorkeeper::Application.new(
      name: params["client_name"],
      redirect_uri: params.require("redirect_uris"),
    )
    client.save!

    render json: {
      client_id: client.uid,
      client_secret: client.secret,
      client_secret_expires_at: 0,
    }
  end
end
