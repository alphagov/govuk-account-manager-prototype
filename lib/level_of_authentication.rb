class LevelOfAuthenticationTooLowError < StandardError; end

module LevelOfAuthentication
  class << self
    def sort_levels_of_authentication(array_of_levels)
      return nil if array_of_levels.empty?

      array_of_levels.sort do |a, b|
        a.delete_prefix("level").to_i <=> b.delete_prefix("level").to_i
      end
    end

    def select_highest_level(array_of_levels)
      return current_maximum_level if array_of_levels.empty?

      sort_levels_of_authentication(array_of_levels).last
    end

    def current_auth_greater_or_equal_to_required(current_auth, required_auth)
      return false if current_auth.nil? || required_auth.nil?

      current_auth.delete_prefix("level").to_i >= required_auth.delete_prefix("level").to_i
    end

    def known_auth_levels_from_hidden_scopes(scopes_path = "./config/scopes.yml")
      scopes = YAML.load_file(scopes_path)
      scopes["hidden_scopes"].select { |scope| scope.starts_with?("level") }
    end

    def current_maximum_level(scopes_path = "./config/scopes.yml")
      select_highest_level(known_auth_levels_from_hidden_scopes(scopes_path))
    end
  end
end
