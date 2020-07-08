class DeviseRegistrationController < Devise::RegistrationsController
  def after_sign_up_path_for(_resource)
    new_user_after_sign_up_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_after_sign_up_path
  end
end
