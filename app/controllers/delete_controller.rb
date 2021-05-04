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

    email = current_user.email
    current_user.destroy!
    sign_out
    UserMailer.with(email: email).post_delete_email.deliver_later
    redirect_to "#{sign_out_path}/logout?continue=delete"
  end

  def confirmation; end
end
