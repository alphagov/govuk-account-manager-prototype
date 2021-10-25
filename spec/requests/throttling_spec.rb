RSpec.describe "Throttling" do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.enabled = false
  end

  context "GET sign-in" do
    it "doesn't throttle" do
      (RATE_LIMIT_COUNT + 1).times { get new_user_session_path }
      expect(response).to_not have_http_status(429)
      expect(response.body).to_not have_content(I18n.t("standard_errors.too_many_requests.heading"))
    end
  end

  context "POST sign-in" do
    it "throttles" do
      (RATE_LIMIT_COUNT + 1).times { post new_user_session_path }
      expect(response).to have_http_status(429)
      expect(response.body).to have_content(I18n.t("standard_errors.too_many_requests.heading"))
    end
  end

  context "GET new-account" do
    it "doesn't throttle" do
      (RATE_LIMIT_COUNT + 1).times { get new_user_registration_start_path }
      expect(response).to_not have_http_status(429)
      expect(response.body).to_not have_content(I18n.t("standard_errors.too_many_requests.heading"))
    end
  end
end
