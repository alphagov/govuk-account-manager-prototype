class Activity < ApplicationRecord
  enum event_type: {
    login: 0,
    change_email_or_password: 1, # pragma: allowlist secret
  }

  belongs_to :user

  def self.login!(user, ip_address)
    new(
      event_type: :login,
      user_id: user.id,
      ip_address: ip_address,
    ).save!
  end

  def self.login_with!(user, oauth_application, ip_address)
    new(
      event_type: :login,
      user_id: user.id,
      oauth_application_id: oauth_application.id,
      ip_address: ip_address,
    ).save!
  end

  def self.change_email_or_password!(user, ip_address)
    new(
      event_type: :change_email_or_password,
      user_id: user.id,
      ip_address: ip_address,
    ).save!
  end

  def client
    if oauth_application_id.nil?
      AccountManagerApplication::NAME
    else
      Doorkeeper::Application.find(oauth_application_id).name
    end
  end
end
