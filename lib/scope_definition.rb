class ScopeDefinition
  attr_reader :scopes

  def initialize
    @scopes = load_scopes_from_yaml
  end

  def default_scopes
    scopes[:default_scopes].map(&:to_sym)
  end

  def optional_scopes
    scopes[:optional_scopes].map(&:to_sym) + development_scopes
  end

  def hidden_scopes
    scopes[:hidden_scopes].map(&:to_sym)
  end

  def development_scopes
    Rails.env.production? ? [] : %i[test_scope_read test_scope_write]
  end

  def development_attributes_and_scopes
    Rails.env.production? ? {} : { test: %i[test_scope_write] }
  end

private

  def load_scopes_from_yaml
    YAML.safe_load(File.read(Rails.root.join("config/scopes.yml"))).symbolize_keys
  end
end
