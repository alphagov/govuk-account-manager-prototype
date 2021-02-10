class DeleteController < ApplicationController
  include ApplicationHelper

  before_action :authenticate_user!, only: %i[show destroy]

  def show; end

  def destroy
    unless current_user.valid_password? params[:current_password]
      @password_error_message = I18n.t("activerecord.errors.models.user.attributes.password.#{params[:current_password].blank? ? 'blank' : 'invalid'}")
      render :show
      return
    end
    User.transaction do
      event_json = record_security_event(SecurityActivity::USER_DESTROYED, user: current_user, log_to_splunk: false).to_hash.to_json
      email = current_user.email
      current_user.destroy!
    end

    Rails.logger.public_send Rails.application.config.log_level, event_json
    sign_out
    UserMailer.with(email: email).post_delete_email.deliver_later
    redirect_to "#{transition_checker_path}/logout?continue=delete"
  end

  def confirmation; end
end
