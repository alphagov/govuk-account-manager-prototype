RSpec.describe "security page pagination" do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

  shared_examples "exactly one page" do |path_helper|
    it "the first page does not have a previous link and does not have a next link" do
      get path_helper.call(1)

      expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_previous"))
      expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_next"))
    end
  end

  shared_examples "exactly two pages" do |path_helper|
    it "the first page does not have a previous link and has a next link" do
      get path_helper.call(1)

      expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_previous"))
      expect(response.body).to have_content(I18n.t("account.security.page_numbering_next"))
    end

    it "the second page has a previous link and does not have a next link" do
      get path_helper.call(2)

      expect(response.body).to have_content(I18n.t("account.security.page_numbering_previous"))
      expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_next"))
    end
  end

  shared_examples "exactly three pages" do |path_helper|
    it "the first page does not have a previous link and has a next link" do
      get path_helper.call(1)

      expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_previous"))
      expect(response.body).to have_content(I18n.t("account.security.page_numbering_next"))
    end

    it "the second page has a previous and next link" do
      get path_helper.call(2)

      expect(response.body).to have_content(I18n.t("account.security.page_numbering_previous"))
      expect(response.body).to have_content(I18n.t("account.security.page_numbering_next"))
    end

    it "the third page has a previous link and does not have a next link" do
      get path_helper.call(3)

      expect(response.body).to have_content(I18n.t("account.security.page_numbering_previous"))
      expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_next"))
    end

    it "shows an error if the page does not exist" do
      get path_helper.call(4)

      expect(response.body).to have_content(I18n.t("account.security.page_out_of_range"))
    end
  end

  context "security activities" do
    context "when there are more than 3 events" do
      before do
        4.times do
          SecurityActivity.create!(
            event_type: SecurityActivity::LOGIN_SUCCESS.id,
            user_id: user.id,
            ip_address: "1.1.1.1",
            ip_address_country: "GB",
          )
        end
      end

      it "only the first 3 are shown in the summary" do
        expect_event_on_security_page(SecurityActivity::LOGIN_SUCCESS, count: 3)
      end
    end

    context "when there is one page of events" do
      before do
        5.times do
          SecurityActivity.create!(
            event_type: SecurityActivity::LOGIN_SUCCESS.id,
            user_id: user.id,
            ip_address: "1.1.1.1",
            ip_address_country: "GB",
          )
        end
      end

      it "the first page has 5 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 1, count: 5)
      end

      include_examples "exactly one page",
                       ->(page) { Rails.application.routes.url_helpers.account_security_paginated_activity_path(page_number: page) }
    end

    context "when there are two pages of events" do
      before do
        15.times do
          SecurityActivity.create!(
            event_type: SecurityActivity::LOGIN_SUCCESS.id,
            user_id: user.id,
            ip_address: "1.1.1.1",
            ip_address_country: "GB",
          )
        end
      end

      it "the second page has 5 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 2, count: 5)
      end

      it "the first page has 10 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 1, count: 10)
      end

      include_examples "exactly two pages",
                       ->(page) { Rails.application.routes.url_helpers.account_security_paginated_activity_path(page_number: page) }
    end

    context "when there are three pages of events" do
      before do
        25.times do
          SecurityActivity.create!(
            event_type: SecurityActivity::LOGIN_SUCCESS.id,
            user_id: user.id,
            ip_address: "1.1.1.1",
            ip_address_country: "GB",
          )
        end
      end

      it "the third page has 5 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 3, count: 5)
      end

      include_examples "exactly three pages",
                       ->(page) { Rails.application.routes.url_helpers.account_security_paginated_activity_path(page_number: page) }
    end

    def expect_event_on_security_page(event, count: 1)
      get account_security_path
      expect(response.body).to have_content(I18n.t("account.security.event.#{event.name}"), count: count)
    end

    def expect_event_on_paginated_security_page(event, page_number:, count:)
      get account_security_paginated_activity_path(page_number: page_number)
      expect(response.body).to have_content(I18n.t("account.security.event.#{event.name}"), count: count)
    end
  end

  context "MFA tokens" do
    context "when there are more than 3 events" do
      before do
        4.times { MfaToken.create!(user_id: user.id, token: "") }
      end

      it "only the first 3 are shown in the summary" do
        expect_mfa_token_on_security_page(count: 3)
      end
    end

    context "when there is one page of events" do
      before do
        5.times { MfaToken.create!(user_id: user.id, token: "") }
      end

      it "the first page has 5 events" do
        expect_mfa_token_on_paginated_security_page(page_number: 1, count: 5)
      end

      include_examples "exactly one page",
                       ->(page) { Rails.application.routes.url_helpers.account_security_paginated_mfa_tokens_path(page_number: page) }
    end

    context "when there are two pages of events" do
      before do
        15.times { MfaToken.create!(user_id: user.id, token: "") }
      end

      it "the first page has 10 events" do
        expect_mfa_token_on_paginated_security_page(page_number: 1, count: 10)
      end

      it "the second page has 5 events" do
        expect_mfa_token_on_paginated_security_page(page_number: 2, count: 5)
      end

      include_examples "exactly two pages",
                       ->(page) { Rails.application.routes.url_helpers.account_security_paginated_mfa_tokens_path(page_number: page) }
    end

    context "when there are three pages of events" do
      before do
        25.times { MfaToken.create!(user_id: user.id, token: "") }
      end

      it "the first page has 10 events" do
        expect_mfa_token_on_paginated_security_page(page_number: 1, count: 10)
      end

      it "the second page has 10 events" do
        expect_mfa_token_on_paginated_security_page(page_number: 2, count: 10)
      end

      it "the third page has 5 events" do
        expect_mfa_token_on_paginated_security_page(page_number: 3, count: 5)
      end

      include_examples "exactly three pages",
                       ->(page) { Rails.application.routes.url_helpers.account_security_paginated_mfa_tokens_path(page_number: page) }
    end

    def expect_mfa_token_on_security_page(count: 1)
      get account_security_path
      expect(response.body).to have_content(I18n.t("account.security.security_codes.code_description.present"), count: count)
    end

    def expect_mfa_token_on_paginated_security_page(page_number:, count:)
      get account_security_paginated_mfa_tokens_path(page_number: page_number)
      expect(response.body).to have_content(I18n.t("account.security.security_codes.code_description.present"), count: count)
    end
  end
end
