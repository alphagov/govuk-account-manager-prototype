RSpec.describe "/api/v1/report/general" do
  let(:user) { FactoryBot.create(:user) }

  let(:application) { FactoryBot.create(:oauth_application) }

  let(:token) do
    FactoryBot.create(
      :oauth_access_token,
      resource_owner_id: user.id,
      application_id: application.id,
      scopes: %i[reporting_access],
    )
  end

  let(:headers) do
    {
      Accept: "application/json",
      Authorization: "Bearer #{token.token}",
    }
  end

  let(:params) do
    {
      start_date: start_date,
      end_date: end_date,
      humanize: humanize,
    }.compact
  end

  let(:start_date) { "2020-01-01 15:00:00" }
  let(:end_date) { "2020-01-01 15:00:00" }
  let(:humanize) { nil }

  it "returns a JSON report" do
    get api_v1_report_general_path, params: params, headers: headers
    expect(response).to be_successful

    empty_report = {
      "users" => {
        "count" => 0,
        "cookie_consents" => {},
        "feedback_consents" => {},
      },
      "logins" => {
        "count" => 0,
        "accounts" => 0,
        "frequency" => [],
        "frequency_ex_confirm" => [],
      },
    }

    body = JSON.parse(response.body)
    expect(body).to eq({ "all" => empty_report, "interval" => empty_report, "start_date" => start_date, "end_date" => end_date })
  end

  context "with the start_date missing" do
    let(:start_date) { nil }

    it "throws a 400" do
      get api_v1_report_general_path, params: params, headers: headers
      expect(response).to have_http_status(400)
    end
  end

  context "with the end_date missing" do
    let(:end_date) { nil }

    it "throws a 400" do
      get api_v1_report_general_path, params: params, headers: headers
      expect(response).to have_http_status(400)
    end
  end

  context "humanize=1" do
    let(:humanize) { "1" }

    it "returns humanized output" do
      get api_v1_report_general_path, params: params, headers: headers
      expect(response).to be_successful

      body = JSON.parse(response.body)
      expect(body.count).to eq(1)
      expect(body.first["title"]).to eq("Daily Statistics")
      expect(body.first["text"]).to start_with("All registrations to #{end_date}")
    end
  end
end
