unless Rails.env.production?
  Doorkeeper::AccessToken.destroy_all
  Doorkeeper::Application.destroy_all

  app = Doorkeeper::Application.create!(
    name: "GOV.UK Attribute Service",
    redirect_uri: "http://localhost",
    scopes: [:deanonymise_tokens],
  )

  token = Doorkeeper::AccessToken.create!(
    application_id: app.id,
    scopes: [:deanonymise_tokens],
  )

  token.token = "attribute-service-token"
  token.save!
end
