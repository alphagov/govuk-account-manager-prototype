# frozen_string_literal: true

module ApplicationHelper
  def date_with_time_ago(unix_epoch_miliseconds)
    time = Time.zone.strptime(unix_epoch_miliseconds.to_s, "%Q")
    "#{time.strftime('%d %B %Y at %H:%M')} (#{time_ago_in_words(time)} ago)"
  end
end
