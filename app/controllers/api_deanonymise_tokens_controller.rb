class ApiDeanonymiseTokensController < ApplicationController
  before_action -> { doorkeeper_authorize! :deanonymise_tokens }

  respond_to :json

  def show
    if token.nil?
      head 404
    elsif token.expired?
      head 410
    else
      respond_with token.as_json
    end
  end

private

  def token
    @token ||= Doorkeeper::AccessToken.find_by(token: params.fetch(:token))
  end
end
