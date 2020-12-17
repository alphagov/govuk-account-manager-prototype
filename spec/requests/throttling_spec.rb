RSpec.describe "Throttling" do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.enabled = false
  end

  context "POST /sign-in" do
    it "throttles" do
      (LIMIT_LOGIN_ATTEMPTS_PER_IP + 1).times { post new_user_session_path, params: { "user[email]" => "email@example.com" } }
      expect(response).to have_http_status(429)
      expect(response.body).to have_content(I18n.t("standard_errors.too_many_requests.heading"))
    end
  end
end
