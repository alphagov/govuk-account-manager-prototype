RSpec.describe "Throttling" do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.enabled = false
  end

  context "POST /" do
    it "does not throttle" do
      (LIMIT_LOGIN_ATTEMPTS_PER_IP + 1).times { post "/" }
      expect(response.body).to_not have_content(I18n.t("standard_errors.too_many_requests.heading"))
    end

    context "with user[email] set" do
      it "throttles" do
        (LIMIT_LOGIN_ATTEMPTS_PER_IP + 1).times { post "/", params: { "user[email]" => "email@example.com" } }
        follow_redirect!
        expect(response.body).to have_content(I18n.t("standard_errors.too_many_requests.heading"))
      end
    end
  end

  context "POST /login" do
    it "throttles" do
      (LIMIT_LOGIN_ATTEMPTS_PER_IP + 1).times { post "/login" }
      follow_redirect!
      expect(response.body).to have_content(I18n.t("standard_errors.too_many_requests.heading"))
    end
  end
end
