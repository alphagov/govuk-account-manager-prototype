require "spec_helper"

RSpec.describe "delete account requests" do
  context "when logged out" do
    it "redirects GET /account/delete requests to the login form" do
      get account_delete_path
      follow_redirect!
      expect(response.body).to have_text(I18n.t("devise.sessions.new.heading"))
    end

    it "redirects DELETE /account/delete requests to the login form" do
      delete account_delete_path
      follow_redirect!
      expect(response.body).to have_text(I18n.t("devise.sessions.new.heading"))
    end

    it "GET /account/delete/confirmation renders confirmation text" do
      get account_delete_confirmation_path
      expect(response.body).to have_text(I18n.t("account.delete.confirmation.heading"))
    end
  end

  context "when logged in" do
    let(:user) { FactoryBot.create(:user) }
    let(:account_api_application) { FactoryBot.create(:oauth_application) }
    let(:account_api_subject_identifier) { Doorkeeper::OpenidConnect.configuration.subject.call(user, account_api_application).to_s }

    before { sign_in(user) }

    describe "GET /delete" do
      it "renders the form" do
        get account_delete_path
        expect(response.body).to have_text(I18n.t("account.delete.heading"))
      end
    end

    describe "DELETE /delete" do
      let(:instance) { instance_double(RemoteUserInfo) }
      let(:double_class) { class_double(RemoteUserInfo).as_stubbed_const }

      it "renders the form if current user does not have a valid password" do
        allow(user).to receive(:valid_password?).and_return(false)
        delete account_delete_path
        expect(response.body).to have_text(I18n.t("account.delete.heading"))
      end

      it "deletes account in the account manager and api and sends an email if current users password is valid" do
        allow(user).to receive(:valid_password?).and_return(true)
        allow(double_class).to receive(:new).and_return(instance)
        allow(instance).to receive(:destroy!).and_return(true)
        ClimateControl.modify ACCOUNT_API_DOORKEEPER_UID: account_api_application.uid do
          expect { delete account_delete_path }.to change(User, :count).by(-1)
        end
      end
    end
  end
end
