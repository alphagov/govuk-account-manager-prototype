class ApiDeanonymiseTokenController < ApplicationController
  before_action -> { doorkeeper_authorize! :deanonymise_tokens }

  respond_to :json

  rescue_from ActionController::ParameterMissing do
    head 400
  end

  def show
    if token.nil?
      head 404
    elsif token.expired?
      head 410
    else
      render json: {
        true_subject_identifier: token.resource_owner_id,
        pairwise_subject_identifier: Doorkeeper::OpenidConnect::UserInfo.new(token).claims[:sub],
        scopes: token.scopes.to_a,
      }
    end
  end

private

  def token
    @token ||= Doorkeeper::AccessToken.find_by(token: params.fetch(:token))
  end
end
