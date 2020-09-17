RSpec.describe "feedback" do
  describe "GET" do
    it "renders the form" do
      get feedback_path

      expect(response.body).to have_content(I18n.t("feedback.title"))
    end
  end
end
