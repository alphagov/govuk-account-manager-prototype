class Jwt < ApplicationRecord
  has_one :registration_state
  has_one :login_state

  scope :without_login_states, -> { left_joins(:login_state).where("login_states.jwt_id IS NULL") }
  scope :without_registration_states, -> { left_joins(:registration_state).where("registration_states.jwt_id IS NULL") }
end
