require "spec_helper"

RSpec.describe "/account" do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

  it "shows the service card" do
    get user_root_path

    expect(response.body).to have_content(I18n.t("account.your_account.transition.heading"))
  end
end
