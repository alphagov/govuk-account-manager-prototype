RSpec.describe "new-password" do
  describe "GET /new-password" do
    it "renders the form" do
      get new_password_path

      expect(response.body).to have_content(I18n.t("new_password.title"))
    end
  end
end
