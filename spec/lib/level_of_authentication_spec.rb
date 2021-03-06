RSpec.describe LevelOfAuthentication do
  describe "#sort_levels_of_authentication" do
    it "returns a sorted array of auth levels" do
      array = %w[level4 level0 level2]

      expect(
        LevelOfAuthentication.sort_levels_of_authentication(array),
      ).to eq(%w[level0 level2 level4])
    end

    it "sorts correctly for double and triple digit numbers" do
      array = %w[level0 level100 level10 level1]

      expect(
        LevelOfAuthentication.sort_levels_of_authentication(array),
      ).to eq(%w[level0 level1 level10 level100])
    end
  end

  describe "#select_highest_level" do
    it "returns the highest level as a string" do
      array = %w[level0 level100 level10 level1]

      expect(
        LevelOfAuthentication.select_highest_level(array),
      ).to eq("level100")
    end

    it "returns the current_maximum_level if provided an empty array" do
      expect(
        LevelOfAuthentication.select_highest_level([]),
      ).to eq(LevelOfAuthentication.current_maximum_level)
    end
  end

  describe "#current_auth_greater_or_equal_to_required" do
    it "returns true that level1 is higher than level0" do
      expect(LevelOfAuthentication.current_auth_greater_or_equal_to_required("level1", "level0")).to be true
    end

    it "returns true that level10 is higher than level1" do
      expect(LevelOfAuthentication.current_auth_greater_or_equal_to_required("level10", "level1")).to be true
    end

    it "returns true that level1 is equal to level1" do
      expect(LevelOfAuthentication.current_auth_greater_or_equal_to_required("level1", "level1")).to be true
    end

    it "returns false that level1 is higher than level1000" do
      expect(LevelOfAuthentication.current_auth_greater_or_equal_to_required("level1", "level1000")).to be false
    end
  end

  describe "#known_auth_levels_from_hidden_scopes" do
    it "returns an array of hidden scopes, filtered to known level of auth scopes" do
      expect(
        LevelOfAuthentication.known_auth_levels_from_hidden_scopes("./spec/fixtures/scopes.yml"),
      ).to eq(%w[level0 level1])
    end
  end

  describe "current_maximum_level" do
    it "returns the highest known level of auth scope" do
      expect(
        LevelOfAuthentication.current_maximum_level("./spec/fixtures/scopes.yml"),
      ).to eq("level1")
    end
  end
end
