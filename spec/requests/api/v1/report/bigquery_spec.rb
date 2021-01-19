RSpec.describe "/api/v1/report/bigquery" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

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
    }.compact
  end

  let(:start_date) { Time.zone.parse("2020-01-01 15:00:00") }
  let(:end_date) { Time.zone.parse("2020-01-01 15:00:00") }

  it "returns a 202" do
    post api_v1_report_bigquery_path, params: params, headers: headers
    expect(response).to have_http_status(202)
  end

  it "enqueues a job" do
    post api_v1_report_bigquery_path, params: params, headers: headers
    assert_enqueued_jobs 1, only: BigqueryReportExportJob
  end

  context "with the start_date missing" do
    let(:start_date) { nil }

    it "uses yesterday at 3PM" do
      travel_to Time.zone.local(2020, 1, 1, 10, 0, 0) do
        post api_v1_report_bigquery_path, params: params, headers: headers
        expect(response).to have_http_status(202)
        expect(JSON.parse(response.body)["start_date"]).to eq("2019-12-31 15:00:00 +00:00")
      end
    end
  end

  context "with the end_date missing" do
    let(:end_date) { nil }

    it "uses today at 3PM" do
      travel_to Time.zone.local(2020, 1, 1, 10, 0, 0) do
        post api_v1_report_bigquery_path, params: params, headers: headers
        expect(response).to have_http_status(202)
        expect(JSON.parse(response.body)["end_date"]).to eq("2020-01-01 15:00:00 +00:00")
      end
    end
  end

  context "with an invalid date" do
    let(:start_date) { "breadbread" }

    it "returns a 400" do
      post api_v1_report_bigquery_path, params: params, headers: headers
      expect(response).to have_http_status(400)
    end
  end
end
