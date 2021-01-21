class SetAttributesJob < ApplicationJob
  queue_as :default

  def perform(access_token_id, attributes)
    token = Doorkeeper::AccessToken.find(access_token_id)
    RestClient.post(
      "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes",
      { attributes: attributes.transform_values(&:to_json) },
      { accept: :json, authorization: "Bearer #{token.token}" },
    )
  end
end
