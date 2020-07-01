require "email_confirmation"

class ChangeEmailController < ApplicationController
  before_action :authenticate_user!
  rescue_from RestClient::Conflict, with: :conflict

  def show; end

  def submit
    if request_errors.empty?
      @email = register_params[:email]
      EmailConfirmation.change_and_send(@user, @email)
    else
      flash[:validation] = request_errors

      redirect_to action: :show, params: register_params
    end
  end

private

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

  def conflict
    @email = params[:email]
    render action: "conflict", status: :conflict
  end
end
