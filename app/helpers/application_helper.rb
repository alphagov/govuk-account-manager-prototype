# frozen_string_literal: true

module ApplicationHelper
  def date_with_time_ago(datetime)
    "#{datetime.strftime('%d %B %Y at %H:%M')} (#{time_ago_in_words(datetime)} ago)"
  end

  def navigation_items
    if user_signed_in?
      [
        {
          text: t("navigation.user_root_path"),
          href: user_root_path,
          active: true,
        },
        {
          text: t("navigation.destroy_user_session"),
          href: destroy_user_session_path,
        },
      ]
    else
      []
    end
  end
end
