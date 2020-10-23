RSpec.describe "/healthcheck", type: :request do
  before do
    # redis is not connected in test mode
    stub_const("Sidekiq", double(:sidekiq, redis_info: double(:redis_info)))
  end

  it "returns ok" do
    get healthcheck_path

    expect(JSON.parse(response.body)["status"]).to eq("ok")
  end
end
