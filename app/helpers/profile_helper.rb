module ProfileHelper
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
