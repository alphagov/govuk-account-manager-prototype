class ChangeEmailController < ApplicationController
  before_action :authenticate_user!

  def show; end

  def submit
    if request_errors.empty? && email_confirm_matches
      @email = register_params[:email]
      if update_email(@user.id, @email).code == 204
        EmailConfirmation.send(@user)
        redirect_to action: :confirm_email
      end
    else
      flash[:validation] = request_errors

      redirect_to action: :show, params: register_params
    end
  end

  def confirm_email; end

private

  def update_email(user_id, email)
    rep = { "email" => email, "emailVerified" => false }
    Services.keycloak.users.update(user_id, KeycloakAdmin::UserRepresentation.from_hash(rep))
  end

  def email_confirm_matches
    register_params[:email] == register_params[:email_confirm]
  end

  def request_errors
    errors = []

    if register_params[:email].blank?
      errors << {
        field: "email",
        text: t("change_email.error.email_missing"),
      }
    elsif !register_params[:email].include?("@")
      errors << {
        field: "email",
        text: t("change_email.error.new_email_invalid"),
      }
    end

    if register_params[:email_confirm].blank?
      errors << {
        field: "email_confirm",
        text: t("change_email.error.confirm_email_missing"),
      }
    end

    unless email_confirm_matches
      errors << {
        field: "email_confirm",
        text: t("change_email.error.confirm_email_no_match"),
      }
    end

    errors
  end

  def register_params
    params.permit(:email, :email_confirm)
  end
end
