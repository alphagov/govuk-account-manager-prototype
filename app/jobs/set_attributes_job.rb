class SetAttributesJob < ApplicationJob
  queue_as :default

  def perform(access_token_id, attributes)
    token = Doorkeeper::AccessToken.find(access_token_id)
    attributes.each do |key, value|
      RestClient.put(
        "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes/#{key}",
        { value: value.to_json },
        { accept: :json, authorization: "Bearer #{token.token}" },
      )
    end
  end
end
