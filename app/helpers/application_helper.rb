# frozen_string_literal: true

module ApplicationHelper
  def date_with_time_ago(unix_epoch_miliseconds)
    datetime = Time.zone.at(unix_epoch_miliseconds / 1000).to_datetime
    "#{datetime.strftime('%d %B %Y at %H:%M')} (#{time_ago_in_words(datetime)} ago)"
  end
end
