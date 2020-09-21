class DeviseSessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate(auth_options)
    if resource
      # from https://github.com/heartcombo/devise/blob/45b831c4ea5a35914037bd27fe88b76d7b3683a4/app/controllers/devise/sessions_controller.rb#L18
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      @password_error_message = I18n.t("devise.sessions.new.fields.password.errors.incorrect")
      begin
        user = User.find_by(email: params.dig(:user, :email))
        if user.locked_at?
          @password_error_message = I18n.t("devise.sessions.new.fields.password.errors.locked")
        end
      rescue ActiveRecord::RecordNotFound # rubocop:disable Lint/SuppressedException
      end
      render :new
    end
  end
end
