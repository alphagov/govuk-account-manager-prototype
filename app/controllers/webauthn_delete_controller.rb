class WebauthnDeleteController < ApplicationController
  before_action :authenticate_user!
  before_action :security_key

  def show
    redirect_unless_security_key(account_security_path)
  end

  def destroy
    redirect_unless_security_key(account_security_path)
    security_key.destroy! if security_key
    redirect_to account_security_path(anchor: "security-keys")
  end

private

  def redirect_unless_security_key(redirect_path)
    flash[:alert] = t("mfa.errors.webauthn.delete.no_key_found")
    redirect_to redirect_path unless security_key
  end

  def security_key
    @security_key ||= current_user.webauthn_credentials.find(params[:key_id])
  end
end
