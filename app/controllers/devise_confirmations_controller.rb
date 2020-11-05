class DeviseConfirmationsController < Devise::ConfirmationsController
  def after_resending_confirmation_instructions_path_for(_resource_name)
    new_user_after_sign_up_path
  end
end
