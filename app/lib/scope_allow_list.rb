class ScopeAllowList
  attr_reader :scopes

  def initialize
    @scopes = load_scopes_from_yaml
  end

  def default_scopes
    scopes[:default_scopes].map(&:to_sym)
  end

  def optional_scopes
    scopes[:optional_scopes].map(&:to_sym)
  end

private

  def load_scopes_from_yaml
    YAML.safe_load(File.read(Rails.root.join("config/scopes.yml"))).symbolize_keys
  end
end
