class ChangeRedirectUrlsForFrontend < ActiveRecord::Migration[6.0]
  def up
    Doorkeeper::Application.where(
      redirect_uri: "http://finder-frontend.dev.gov.uk/transition-check/login/callback",
    ).each do |dev_app|
      dev_app.update!(
        redirect_uri: [
          "http://frontend.dev.gov.uk/sign-in/callback",
          "http://finder-frontend.dev.gov.uk/transition-check/login/callback",
        ],
      )
    end

    Doorkeeper::Application.where(
      redirect_uri: "https://www.integration.publishing.service.gov.uk/transition-check/login/callback",
    ).each do |integration_app|
      integration_app.update!(
        redirect_uri: [
          "https://www.integration.publishing.service.gov.uk/sign-in/callback",
          "https://www.integration.publishing.service.gov.uk/transition-check/login/callback"
        ],
      )
    end

    Doorkeeper::Application.where(
      redirect_uri: "https://www.staging.publishing.service.gov.uk/transition-check/login/callback",
    ).each do |staging_app|
      staging_app.update!(
        redirect_uri: [
          "https://www.staging.publishing.service.gov.uk/sign-in/callback",
          "https://www.staging.publishing.service.gov.uk/transition-check/login/callback"
        ],
      )
    end

    Doorkeeper::Application.where(
      redirect_uri: "https://www.gov.uk/transition-check/login/callback",
    ).each do |production_app|
      production_app.update!(
        redirect_uri: [
          "https://www.gov.uk/sign-in/callback",
          "https://www.gov.uk/transition-check/login/callback"
        ],
      )
    end
  end
end
