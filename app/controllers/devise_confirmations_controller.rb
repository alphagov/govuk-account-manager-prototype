class DeviseConfirmationsController < Devise::ConfirmationsController
  def sent
    if session[:confirmations]
      @email = session[:confirmations]["email"]
      @user_is_confirmed = session[:confirmations].fetch("user_is_confirmed", false)
      @user_is_new = session[:confirmations].fetch("user_is_new", false)
      session.delete(:confirmations)
    else
      redirect_to "/"
    end
  end

  def show
    super do
      if resource.errors.empty?
        record_security_event(SecurityActivity::EMAIL_CHANGED, user: resource, notes: "to #{resource.email}")
      elsif resource.errors.details[:email].first&.dig(:error) == :already_confirmed
        if current_user
          redirect_to user_root_path
        else
          redirect_to "/", flash: { notice: I18n.t("errors.messages.already_confirmed") }
        end
        return
      end
    end
  end

  def new
    super
    @email = current_user&.unconfirmed_email || current_user&.email
  end

  def after_resending_confirmation_instructions_path_for(_resource_name)
    session[:confirmations] = {
      email: resource.unconfirmed_email,
      user_is_confirmed: resource.confirmed?,
    }
    confirmation_email_sent_path
  end
end
