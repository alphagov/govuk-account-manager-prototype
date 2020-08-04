class AccountManagerApplication
  NAME = "GOV.UK Account Manager".freeze
  REDIRECT_URI = Rails.application.config.redirect_base_url
  SCOPES = %i[account_manager_access].freeze

  def self.fetch
    new.fetch
  end

  def fetch
    @fetch ||= Doorkeeper::Application.transaction do
      application = find_application
      application.nil? ? create_application : application
    end
  end

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
end
