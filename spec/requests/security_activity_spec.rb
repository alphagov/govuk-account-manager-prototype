RSpec.describe "security activities" do
  let(:user) { FactoryBot.create(:user) }

  context "registering a new user" do
    let(:registration_state) { FactoryBot.create(:registration_state, :finished) }

    it "records USER_CREATED events" do
      # Stub the Registration State to sneak past redirect safeguards
      allow(RegistrationState).to receive(:find).with(nil).and_return(registration_state)

      get new_user_registration_finish_path
      expect_event SecurityActivity::USER_CREATED, { user: User.first }
    end
  end

  it "records ACCOUNT_LOCKED events" do
    (Devise.maximum_attempts + 1).times do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => "incorrect" }
    end

    expect_event SecurityActivity::ACCOUNT_LOCKED
    expect_event_on_security_page SecurityActivity::ACCOUNT_LOCKED
  end

  it "records MANUAL_ACCOUNT_UNLOCK events" do
    unlock_token = user.lock_access!
    get user_unlock_path(unlock_token: unlock_token)
    user.reload

    expect_event SecurityActivity::MANUAL_ACCOUNT_UNLOCK
    expect_event_on_security_page SecurityActivity::MANUAL_ACCOUNT_UNLOCK
  end

  context "with MFA enabled" do
    before { allow(Rails.configuration).to receive(:feature_flag_mfa).and_return(true) }
    before { allow(Rails.configuration).to receive(:feature_flag_bypass_mfa).and_return(true) }

    it "records ADDITIONAL_FACTOR_VERIFICATION_SUCCESS events" do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
      post user_session_phone_verify_path, params: { "phone_code" => user.reload.phone_code }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_SUCCESS, { factor: :sms }
    end

    it "records ADDITIONAL_FACTOR_VERIFICATION_SUCCESS event with additional analytics data from confirmation email" do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
      post user_session_phone_verify_path, params: { "phone_code" => user.reload.phone_code, "from_confirmation_email" => true }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_SUCCESS, { analytics: "from_confirmation_email" }
    end

    it "records ADDITIONAL_FACTOR_VERIFICATION_FAILURE events" do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
      post user_session_phone_verify_path, params: { "phone_code" => "incorrect" }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_FAILURE, { factor: :sms }
      expect_event_on_security_page SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_FAILURE
    end

    it "records ADDITIONAL_FACTOR_VERIFICATION_FAILURE event with additional analytics data from confirmation email" do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
      post user_session_phone_verify_path, params: { "phone_code" => "incorrect", "from_confirmation_email" => true }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_FAILURE, { analytics: "from_confirmation_email" }
      expect_event_on_security_page SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_FAILURE
    end

    it "records ADDITIONAL_FACTOR_BYPASS_USED events" do
      allow_any_instance_of(ActionDispatch::Cookies::CookieJar).to receive(:encrypted)
        .and_return({ SessionsController::MFA_BYPASS_COOKIE_NAME => { user.email => MfaToken.generate!(user).token } })

      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_BYPASS_USED
    end

    it "records ADDITIONAL_FACTOR_BYPASS_USED event with additional analytics data from confirmation email" do
      allow_any_instance_of(ActionDispatch::Cookies::CookieJar).to receive(:encrypted)
        .and_return({ SessionsController::MFA_BYPASS_COOKIE_NAME => { user.email => MfaToken.generate!(user).token } })

      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password, "from_confirmation_email" => true }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_BYPASS_USED, analytics: "from_confirmation_email"
    end

    it "records ADDITIONAL_FACTOR_BYPASS_GENERATED events" do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
      post user_session_phone_verify_path, params: { "phone_code" => user.reload.phone_code, "remember_me" => 1 }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_BYPASS_GENERATED
    end

    it "records ADDITIONAL_FACTOR_BYPASS_GENERATED event with additional analytics data from confirmation email" do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
      post user_session_phone_verify_path, params: { "phone_code" => user.reload.phone_code, "remember_me" => 1, "from_confirmation_email" => true }

      expect_event SecurityActivity::ADDITIONAL_FACTOR_BYPASS_GENERATED, analytics: "from_confirmation_email"
    end
  end

  it "records LOGIN_SUCCESS events" do
    post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }

    expect_event SecurityActivity::LOGIN_SUCCESS
    expect_event_on_security_page SecurityActivity::LOGIN_SUCCESS
  end

  it "records LOGIN_SUCCESS event with additional analytics data from confirmation email" do
    post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password, "from_confirmation_email" => true }

    expect_event SecurityActivity::LOGIN_SUCCESS, analytics: "from_confirmation_email"
    expect_event_on_security_page SecurityActivity::LOGIN_SUCCESS
  end

  it "records LOGIN_FAILURE events" do
    post new_user_session_path, params: { "user[email]" => user.email }
    post response.redirect_url, params: { "user[email]" => user.email, "user[password]" => "incorrect" }

    expect_event SecurityActivity::LOGIN_FAILURE
    expect_event_on_security_page SecurityActivity::LOGIN_FAILURE
  end

  it "records LOGIN_FAILURE event with additional analytics data from confirmation email" do
    post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => "incorrect", "from_confirmation_email" => true }

    expect_event SecurityActivity::LOGIN_FAILURE, { analytics: "from_confirmation_email" }
    expect_event_on_security_page SecurityActivity::LOGIN_FAILURE
  end

  it "records PASSWORD_RESET_REQUEST events" do
    post create_password_path, params: { "user[email]" => user.email }

    expect_event SecurityActivity::PASSWORD_RESET_REQUEST
    expect_event_on_security_page SecurityActivity::PASSWORD_RESET_REQUEST
  end

  it "records PASSWORD_RESET_SUCCESS events" do
    post user_password_path, params: {
      "_method" => "put",
      "user[password]" => "new-password",
      "user[password_confirmation]" => "new-password",
      "user[reset_password_token]" => user.send_reset_password_instructions,
    }

    expect_event SecurityActivity::PASSWORD_RESET_SUCCESS
    expect_event_on_security_page SecurityActivity::PASSWORD_RESET_SUCCESS
  end

  context "with a user logged in" do
    before { sign_in user }

    context "with an OAuth application" do
      let(:application) do
        FactoryBot.create(
          :oauth_application,
          name: "name",
          redirect_uri: "http://localhost",
          scopes: %i[openid],
        )
      end

      it "records LOGIN_SUCCESS events for OAuth authorizations" do
        get authorization_endpoint_url(client: application, scope: "openid")

        expect_event SecurityActivity::LOGIN_SUCCESS, { application: application }
        expect_event_on_security_page SecurityActivity::LOGIN_SUCCESS
      end
    end

    it "records EMAIL_CHANGE_REQUESTED events" do
      post user_registration_path, params: {
        "_method" => "put",
        "user[email]" => "new-email-address@example.com",
        "user[current_password]" => user.password,
      }

      expect_event SecurityActivity::EMAIL_CHANGE_REQUESTED, { notes: "from #{user.email} to #{user.reload.unconfirmed_email}" }
      expect_event_on_security_page SecurityActivity::EMAIL_CHANGE_REQUESTED
    end

    context "with MFA enabled" do
      before do
        allow(Rails.configuration).to receive(:feature_flag_mfa).and_return(true)
        allow(Rails.configuration).to receive(:allow_insecure_change_credential).and_return(true)
      end

      it "records PHONE_CHANGED events" do
        old_phone = user.phone

        post edit_user_registration_phone_code_path, params: {
          "phone" => "07581123456",
          "current_password" => user.password,
        }
        post edit_user_registration_phone_verify_path, params: { "phone_code" => user.phone_code }

        expect_event SecurityActivity::PHONE_CHANGED, { notes: "from #{old_phone} to #{user.reload.phone}" }
        expect_event_on_security_page SecurityActivity::PHONE_CHANGED
      end
    end

    it "records PASSWORD_CHANGED events" do
      post user_registration_path, params: {
        "_method" => "put",
        "user[password]" => "new-password",
        "user[password_confirmation]" => "new-password",
        "user[current_password]" => user.password,
      }

      expect_event SecurityActivity::PASSWORD_CHANGED
      expect_event_on_security_page SecurityActivity::PASSWORD_CHANGED
    end
  end

  it "records EMAIL_CHANGED events" do
    get user_confirmation_path(confirmation_token: user.confirmation_token)

    expect_event SecurityActivity::EMAIL_CHANGED, notes: "to #{user.email}"
    expect_event_on_security_page SecurityActivity::EMAIL_CHANGED
  end

  context "pagination" do
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

        sign_in user
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

        sign_in user
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

        sign_in user
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

  def expect_event(event, options = {})
    event_user = options[:user] || user
    events = event_user.security_activities.of_type(event)
    events = events.where(oauth_application_id: options[:application].id) if options[:application]
    events = events.where(factor: options[:factor]) if options[:factor]
    events = events.where(notes: options[:notes]) if options[:notes]
    events = events.where(analytics: options[:analytics]) if options[:analytics]

    expect(events.count).to_not eq(0)
  end

  def expect_event_on_security_page(event, count: 1)
    sign_in user
    get account_security_path

    expect(response.body).to have_content(I18n.t("account.security.event.#{event.name}"), count: count)
  end

  def expect_event_on_paginated_security_page(event, page_number:, count:)
    get account_security_paginated_activity_path(page_number: page_number)

    expect(response.body).to have_content(I18n.t("account.security.event.#{event.name}"), count: count)
  end
end
