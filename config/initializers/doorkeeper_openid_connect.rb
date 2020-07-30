# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  issuer ENV["OIDC_IDP_ISSUER"]

  signing_key ENV["OIDC_IDP_PRIVATE_KEY"] || (ENV["OIDC_IDP_PRIVATE_KEY_FILE"] ? File.read(ENV["OIDC_IDP_PRIVATE_KEY_FILE"]) : nil)

  subject_types_supported [:pairwise]

  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner(&:current_sign_in_at)

  reauthenticate_resource_owner do |resource_owner, return_to|
    store_location_for resource_owner, return_to
    sign_out resource_owner
    redirect_to new_user_session_url
  end

  # Depending on your configuration, a DoubleRenderError could be raised
  # if render/redirect_to is called at some point before this callback is executed.
  # To avoid the DoubleRenderError, you could add these two lines at the beginning
  #  of this callback: (Reference: https://github.com/rails/rails/issues/25106)
  #   self.response_body = nil
  #   @_response_body = nil
  select_account_for_resource_owner do |resource_owner, return_to|
    # Example implementation:
    store_location_for resource_owner, return_to
    redirect_to new_user_session_url
  end

  subject do |resource_owner, application|
    Digest::SHA256.hexdigest("#{resource_owner.id}#{URI.parse(application.redirect_uri).host}#{ENV['OIDC_IDP_SALT']}")
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  # protocol do
  #   :https
  # end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  # Claims:
  claims do
  end
end

module Doorkeeper::OpenidConnect::Helpers::Controller
  def oauth_userinfo_url(*)
    "#{ENV['ATTRIBUTE_SERVICE_URL']}/oidc/user_info"
  end
end
