class SecurityActivity < ApplicationRecord
  enum event_type: {
    login: 0,
    change_email: 1,
    change_phone: 2,
    change_password: 3, # pragma: allowlist secret
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

  def self.change_email!(user, ip_address)
    new(
      event_type: :change_email,
      user_id: user.id,
      ip_address: ip_address,
    ).save!
  end

  def self.change_password!(user, ip_address)
    new(
      event_type: :change_password,
      user_id: user.id,
      ip_address: ip_address,
    ).save!
  end

  def self.change_phone!(user, ip_address)
    new(
      event_type: :change_phone,
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
