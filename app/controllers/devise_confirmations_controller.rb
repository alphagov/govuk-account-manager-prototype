class DeviseConfirmationsController < Devise::ConfirmationsController
  def sent
    # if the user is new they have an 'email' but not an
    # 'unconfirmed_email', even though it's not been confirmed.
    @email = params[:email] || current_user&.unconfirmed_email || current_user&.email
    @user_is_confirmed = params.fetch(:user_is_confirmed, current_user&.confirmed?)
    @user_is_new = params.fetch(:new_user, false)

    redirect_to "/" unless @email
  end

  def show
    super do
      if resource.errors.details[:email].first&.dig(:error) == :already_confirmed
        if current_user
          redirect_to user_root_path
        else
          redirect_to "/", flash: { notice: I18n.t("errors.messages.already_confirmed") }
        end
        return
      end
    end
  end

  def after_resending_confirmation_instructions_path_for(_resource_name)
    confirmation_email_sent_path(email: resource.unconfirmed_email, user_is_confirmed: resource.confirmed?)
  end
end
