# frozen_string_literal: true

module ManageHelper
  def core_account_details
    email = {
      field: t("general.email"),
      value: current_user.email,
      edit: {
        href: edit_user_registration_email_url,
        text: t("general.change"),
      },
    }

    password = {
      field: t("general.password"),
      value: "********",
      edit: {
        href: edit_user_registration_password_url,
        text: t("general.change"),
      },
    }

    phone = {
      field: t("general.phone"),
      value: current_user.phone,
      edit: {
        href: edit_user_registration_phone_url,
        text: t("general.change"),
      },
    }

    [email, password, current_user.phone ? phone : nil].compact
  end

  def user_details(user_info)
    return unless user_info

    [
      attribute(:email, user_info[:email_verified] ? user_info[:email] : "#{user_info[:email]} (unverified)"),
      attribute(:test, Rails.env.production? ? nil : user_info[:test]),
    ].reject { |detail| detail.fetch(:value).blank? }
  end

  def attribute(key, value)
    {
      field: I18n.t("account.profile.user_details.#{key}"),
      value: value,
    }
  end
end
