RSpec.describe PasswordHelper, type: :helper do
  describe "#password_valid?" do
    it "returns an error if first password is missing" do
      expect(password_valid?("", "foo")).to eq(:password_missing)
    end

    it "returns an error if second password is missing" do
      expect(password_valid?("foo", "")).to eq(:password_confirm_missing)
    end

    it "returns an error if passwords do not match" do
      expect(password_valid?("foo1", "foo2")).to eq(:password_mismatch)
    end

    it "returns an error if password is less than 8 characters" do
      expect(password_valid?("abc1234", "abc1234")).to eq(:password_invalid)
    end

    it "returns an error if password does not contain a number" do
      expect(password_valid?("abcdefghj", "abcdefghj")).to eq(:password_invalid)
    end
  end
end
