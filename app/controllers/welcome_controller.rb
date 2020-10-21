class WelcomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:show]

  def show
    payload = ApplicationKey.validate_jwt!(params[:jwt]) if params[:jwt]

    if current_user
      redirect_to(payload ? payload[:post_login_oauth] : user_root_path)
      return
    end

    @email = params.dig(:user, :email)
    if @email
      if Devise.email_regexp.match? @email
        if User.exists?(email: @email)
          render "devise/sessions/new"
        elsif Rails.configuration.enable_registration
          render "devise/registrations/start"
        else
          render "devise/registrations/closed"
        end
      else
        @email_error_message = I18n.t("welcome.show.fields.email.errors.format")
      end
    end
  end

  # methods needed for the devise templates
  helper_method :devise_mapping, :resource

  def devise_mapping
    @devise_mapping ||= request.env["devise.mapping"]
  end

  def resource; end
end
