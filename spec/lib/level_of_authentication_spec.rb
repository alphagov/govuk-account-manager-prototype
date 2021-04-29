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
    it "returns nil if provided an empty array" do
      expect(LevelOfAuthentication.sort_levels_of_authentication([])).to be_nil
    end
  end

  describe "#select_highest_level" do
    it "returns the highest level as a string" do
      array = %w[level0 level100 level10 level1]

      expect(
        LevelOfAuthentication.select_highest_level(array),
      ).to eq("level100")
    end

    it "returns nil if provided an empty array" do
      expect(LevelOfAuthentication.select_highest_level([])).to be_nil
    end
  end
end
