RSpec.describe "/account/confirmation" do
  let(:user) do
    FactoryBot.create(
      :user,
      email: "user@domain.tld",
      password: "breadbread1", # pragma: allowlist secrets
      password_confirmation: "breadbread1",
    )
  end

  it "creates a job to activate any email subscriptions" do
    get user_confirmation_path(confirmation_token: user.confirmation_token)
    assert_enqueued_jobs 1, only: ActivateEmailSubscriptionsJob
  end
end
