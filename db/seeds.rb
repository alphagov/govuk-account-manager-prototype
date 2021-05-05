if Rails.env.development?
  DataActivity.destroy_all
  SecurityActivity.destroy_all

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

  Doorkeeper::Application.create!(
    name: "GOV.UK Personalisation",
    redirect_uri: [
      "http://finder-frontend.dev.gov.uk/transition-check/login/callback",
      "http://frontend.dev.gov.uk/sign-in/callback",
    ],
    scopes: %i[email openid transition_checker level0 level1],
    uid: "client-id",
    secret: "client-secret",
  )

  Doorkeeper::Application.create!(
    name: "Transition Checker",
    redirect_uri: "http://finder-frontend.dev.gov.uk/transition-check/login/callback",
    scopes: %i[email openid transition_checker level0 level1],
    uid: "transition-checker-id",
    secret: "transition-checker-secret",
  )
end
