RSpec.describe "feedback" do
  describe "GET" do
    it "renders the form" do
      get feedback_path

      expect(response.body).to have_content(I18n.t("feedback.title"))
    end
  end

  describe "POST" do
    let(:params) do
      {
        "email" => "user@digital.cabinet-office.gov.uk",
        "comments" => "This website is amazing",
        "response_required" => "yes",
      }
    end

    %w[comments email response_required].each do |field|
      it "shows an error when required field #{field} is missing" do
        post feedback_path, params: params.except(field)

        expect(response.body).to have_content(I18n.t("feedback.fields.#{field}.not_present_error"))
      end
    end
  end
end
