# frozen_string_literal: true

module ManageHelper
  def core_account_details
    email = {
      field: t("general.email"),
      value: current_user.email + (current_user.confirmed? ? "" : " (#{I18n.t('account.manage.details.unconfirmed')})"),
      edit: {
        href: edit_user_registration_email_url,
        text: t("general.change"),
      },
      data_attributes: {
        module: "gem-track-click",
        "track-category": "account-manage",
        "track-action": "manage-account",
        "track-label": "email",
      },
    }

    password = {
      field: t("general.password"),
      value: "********",
      edit: {
        href: edit_user_registration_password_url,
        text: t("general.change"),
      },
      data_attributes: {
        module: "gem-track-click",
        "track-category": "account-manage",
        "track-action": "manage-account",
        "track-label": "password",
      },
    }

    phone = {
      field: t("general.phone"),
      value: formatted_phone_number(current_user.phone),
      edit: {
        href: edit_user_registration_phone_url,
        text: t("general.change"),
      },
      data_attributes: {
        module: "gem-track-click",
        "track-category": "account-manage",
        "track-action": "manage-account",
        "track-label": "phone",
      },
    }

    [email, password, current_user.phone ? phone : nil].compact
  end
end
