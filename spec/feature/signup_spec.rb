require "spec_helper"
require "pry"

RSpec.feature "Account Sign up", type: :feature do
  include FeaturesHelper

  context "when arriving from a registered application" do
    let(:private_key) { jwt_private_key }
    let(:public_key) { jwt_public_key(private_key) }

    before do
      register_authorised_application(public_key)
    end

    scenario do
      given_i_arrive_with_a_valid_jwt
      and_i_see_enter_your_email_address_form
      and_i_enter_a_valid_email_address
      and_i_click_continue
      and_i_see_create_password_form
      and_i_enter_a_valid_password
      and_i_enter_an_identical_password_confirmation
      and_i_click_continue
      and_i_see_data_protection_form
      and_i_click_continue
      and_i_see_notification_form
      and_i_choose_yes
      and_i_click_continue
      then_i_see_confirm_email_page
      and_i_see_go_to_account_button
    end
  end

  def given_i_arrive_with_a_valid_jwt
    post_jwt_to_root(transition_payload, public_key)
    expect(page.status_code).to eql(200)
  end

  def and_i_see_enter_your_email_address_form
    expect(page).to have_text("Enter your email address")
  end

  def and_i_see_create_password_form
    expect(page).to have_text("Create password")
  end

  def and_i_see_data_protection_form
    expect(page).to have_text("Control how we use information about you")
  end

  def and_i_see_notification_form
    expect(page).to have_text("Do you want to receive emails about the UK transition?")
  end

  def and_i_enter_a_valid_email_address
    fill_in "Enter your email address", with: "test_email@dev.gov.uk"
  end

  def and_i_enter_a_valid_password
    fill_in "Create a new password", with: "testpass1"
  end

  def and_i_enter_an_identical_password_confirmation
    fill_in "Retype password", with: "testpass1"
  end

  def and_i_choose_yes
    choose "Yes"
  end

  def and_i_click_continue
    click_button "Continue"
  end

  def then_i_see_confirm_email_page
    expect(page).to have_text("Confirm your email address")
  end

  def and_i_see_go_to_account_button
    expect(page).to have_link("Go to your GOV.UK account")
  end
end
