module AuthorizationsHelper
  HIDDEN_SCOPES = %w[
    transition_checker
  ].freeze

  def user_authorizable_scopes(pre_auth)
    pre_auth.scopes.without(HIDDEN_SCOPES)
  end
end
