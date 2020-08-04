module ProfileHelper
  def user_details(user_info)
    [
      attribute(user_info, :email_address),
    ].reject { |detail| detail.fetch(:value).blank? }
  end

  def attribute(user_info, key)
    {
      field: I18n.t("account.profile.user_details.#{key}"),
      value: user_info[key],
    }
  end
end
