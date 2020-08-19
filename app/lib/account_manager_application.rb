class AccountManagerApplication
  NAME = "GOV.UK Account Manager".freeze
  REDIRECT_URI = Rails.application.config.redirect_base_url
  SCOPES = %i[account_manager_access].freeze

  def self.application
    Doorkeeper::Application.transaction do
      application = find_application
      application.nil? ? create_application : application
    end
  end

  def self.user_token(user_id)
    Doorkeeper::AccessToken.transaction do
      token = find_token(user_id)
      token.nil? ? create_token(user_id) : token
    end
  end

  class << self
  private

    def find_application
      Doorkeeper::Application.find_by(name: NAME)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def create_application
      Doorkeeper::Application.create!(
        name: NAME,
        redirect_uri: REDIRECT_URI,
        scopes: SCOPES,
      )
    end

    def find_token(user_id)
      Doorkeeper::AccessToken.matching_token_for(
        application,
        user_id,
        Doorkeeper::OAuth::Scopes.from_array(SCOPES),
      )
    end

    def create_token(user_id)
      Doorkeeper::AccessToken.create!(
        application_id: application.id,
        resource_owner_id: user_id,
        scopes: SCOPES,
      )
    end
  end
end
