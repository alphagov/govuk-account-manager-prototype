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

    let(:ticket_attributes) do
      {
        subject: I18n.t("feedback.email_subject"),
        email: params["email"],
        comments: params["comments"],
        response_required: params["response_required"].humanize,
      }
    end

    context "when all required fields are present" do
      it "queues a worker" do
        expect(ZendeskTicketWorker).to receive(:perform_async).once.with(ticket_attributes)

        post feedback_path, params: params
      end
    end

    context "when required fields are missing" do
      %w[comments email response_required].each do |field|
        it "shows an error when required field #{field} is missing" do
          post feedback_path, params: params.except(field)

          expect(response.body).to have_content(I18n.t("feedback.fields.#{field}.not_present_error"))
        end
      end

      it "replays sanitized response for email" do
        post feedback_path, params: { email: "<script>alert()</script>abc@digital.cabinet-office.gov.uk" }

        expect(response.body).to have_selector("input[name='email'][value='abc@digital.cabinet-office.gov.uk']")
      end

      it "replays sanitized response for comments" do
        post feedback_path, params: { comments: "<script>alert()</script>Some text" }

        expect(response.body).to have_selector("textarea[name='comments']", text: "Some text")
      end

      it "replays the response for response required" do
        post feedback_path, params: { response_required: "yes" }

        expect(response.body).to have_selector("input[name='response_required'][value='yes'][checked=checked]")
      end

      it "replays the response for response not required" do
        post feedback_path, params: { response_required: "no" }

        expect(response.body).to have_selector("input[name='response_required'][value='no'][checked=checked]")
      end
    end
  end
end
