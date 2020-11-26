# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += %i[
  _ga
  code
  email
  jwt
  login_state_id
  password
  phone
  registration_state_id
  reset_password_token
]
