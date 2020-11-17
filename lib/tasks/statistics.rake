namespace :statistics do
  desc "Get information on all registrations and logins"
  task :general, %i[start_date end_date] => [:environment] do |_, args|
    args.with_defaults(start_date: Time.zone.parse("15:00:00") - 1.day, end_date: Time.zone.parse("14:59:59"))

    results = ""

    all_users = User
      .where("created_at < ?", args.end_date)

    total_users = all_users
      .count
    results += "All registrations to #{args.end_date}: \n#{total_users}\n\n"

    all_new_users = User
      .where("created_at BETWEEN ? AND ?", args.start_date, args.end_date)

    new_users = all_new_users
      .count
    results += "New registrations between #{args.start_date} and #{args.end_date}: \n#{new_users}\n\n"

    all_cookie_consent = all_users
      .pluck(:cookie_consent)
      .tally
    results += "Cookie consents to #{args.end_date}:\n"
    all_cookie_consent.each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    new_cookie_consent = all_new_users
      .pluck(:cookie_consent)
      .tally
    results += "Cookie consents for registrations between #{args.start_date} and #{args.end_date}:\n"
    new_cookie_consent.each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    all_feedback_consent = all_users
      .pluck(:feedback_consent)
      .tally
    results += "Feedback consents to #{args.end_date}:\n"
    all_feedback_consent.each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    new_feedback_consent = all_new_users
      .pluck(:feedback_consent)
      .tally
    results += "Feedback consents for registrations between #{args.start_date} and #{args.end_date}:\n"
    new_feedback_consent.each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    all_logins = SecurityActivity
      .where(event_type: "login")
      .where(oauth_application_id: nil)
      .where("created_at < ?", args.end_date)
    results += "Total number of logins to #{args.end_date}: \n#{all_logins.count}\n\n"

    interval_logins = all_logins
      .where("created_at BETWEEN ? AND ?", args.start_date, args.end_date)
    results += "Total number of logins between #{args.start_date} and #{args.end_date}: \n#{interval_logins.count}\n\n"

    all_user_logins = all_logins
      .pluck(:user_id)
      .uniq
    results += "Accounts logged in to #{args.end_date}: \n#{all_user_logins.count}\n\n"

    user_logins = interval_logins
      .pluck(:user_id)
      .uniq
    results += "Accounts logged in between #{args.start_date} and #{args.end_date}: \n#{user_logins.count}\n\n"

    all_login_frequency = SecurityActivity
      .where(event_type: "login")
      .where(oauth_application_id: nil)
      .where("created_at < ?", args.end_date)
      .pluck(:user_id)
      .tally
      .values
      .tally
      .sort
    results += "Number of logins per account to #{args.end_date}:\n"
    all_login_frequency.each do |frequency, count|
      results += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
    end
    results += "\n"

    login_frequency = SecurityActivity
      .where(event_type: "login")
      .where(oauth_application_id: nil)
      .where("created_at BETWEEN ? AND ?", args.start_date, args.end_date)
      .pluck(:user_id)
      .tally
      .values
      .tally
      .sort
    results += "Number of logins between #{args.start_date} and #{args.end_date}:\n"
    login_frequency.each do |frequency, count|
      results += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
    end

    output = [{
      title: "Daily Statistics",
      text: results,
    }]

    puts output.to_json
  end
end
