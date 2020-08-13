class ApiRegisterClientController < Doorkeeper::ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  respond_to :json

  rescue_from ActionController::ParameterMissing do |e|
    render status: :bad_request, json: {
      error: "invalid_client_metadata",
      error_description: "Required parameter #{e.param} missing",
    }
  end

  rescue_from ActiveRecord::RecordNotUnique do
    render status: :bad_request, json: {
      error: "invalid_client_name",
      error_description: "Client ID already exists",
    }
  end

  def create
    return head 400 if params["subject_type"].present? && params["subject_type"] != "pairwise"

    client = Doorkeeper::Application.new(
      name: params["client_name"],
      redirect_uri: params.require("redirect_uris"),
      contacts: params["contacts"],
      logo_uri: params["logo_uri"],
      client_uri: params["client_uri"],
      policy_uri: params["policy_uri"],
    )
    client.save!

    render json: {
      client_id: client.uid,
      client_secret: client.secret,
      client_secret_expires_at: 0,
      contacts: client.contacts,
      logo_uri: client.logo_uri,
      client_uri: client.client_uri,
      policy_uri: client.policy_uri,
    }
  end
end
