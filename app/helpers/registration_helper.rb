module RegistrationHelper
  def show_phone_field?
    return true unless Rails.application.config.feature_flag_enforce_levels_of_authentication

    params.dig(:authenticate_to_level) != "level0"
  end
end
