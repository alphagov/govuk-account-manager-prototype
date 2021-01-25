RSpec.describe "security page pagination" do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

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

      it "the first page does not have a previous link and does not have a next link" do
        get account_security_paginated_activity_path(page_number: 1)

        expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_previous"))
        expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_next"))
      end
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

      it "the first page has 10 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 1, count: 10)
      end

      it "the second page has 5 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 2, count: 5)
      end

      it "the first page does not have a previous link and has a next link" do
        get account_security_paginated_activity_path(page_number: 1)

        expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_previous"))
        expect(response.body).to have_content(I18n.t("account.security.page_numbering_next"))
      end

      it "the second page has a previous link and does not have a next link" do
        get account_security_paginated_activity_path(page_number: 2)

        expect(response.body).to have_content(I18n.t("account.security.page_numbering_previous"))
        expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_next"))
      end
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

      it "the first page has 10 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 1, count: 10)
      end

      it "the second page has 10 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 2, count: 10)
      end

      it "the third page has 5 events" do
        expect_event_on_paginated_security_page(SecurityActivity::LOGIN_SUCCESS, page_number: 3, count: 5)
      end

      it "the first page does not have a previous link and has a next link" do
        get account_security_paginated_activity_path(page_number: 1)

        expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_previous"))
        expect(response.body).to have_content(I18n.t("account.security.page_numbering_next"))
      end

      it "the second page has a previous and next link" do
        get account_security_paginated_activity_path(page_number: 2)

        expect(response.body).to have_content(I18n.t("account.security.page_numbering_previous"))
        expect(response.body).to have_content(I18n.t("account.security.page_numbering_next"))
      end

      it "the third page has a previous link and does not have a next link" do
        get account_security_paginated_activity_path(page_number: 3)

        expect(response.body).to have_content(I18n.t("account.security.page_numbering_previous"))
        expect(response.body).not_to have_content(I18n.t("account.security.page_numbering_next"))
      end

      it "shows an error if page does not exist" do
        get account_security_paginated_activity_path(page_number: 4)

        expect(response.body).to have_content(I18n.t("account.security.page_out_of_range"))
      end
    end
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
