module AuthorizationsHelper
  def user_authorizable_scopes(pre_auth)
    hidden_scopes = ScopeDefinition.new.hidden_scopes
    pre_auth.scopes.map(&:to_sym).without(hidden_scopes)
  end
end
