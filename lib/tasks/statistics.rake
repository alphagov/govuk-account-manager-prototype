namespace :statistics do
  desc "Get information on all registrations and logins"
  task :general, %i[start_date end_date] => [:environment] do |_, args|
    args.with_defaults(start_date: Time.zone.parse("15:00:00") - 1.day, end_date: Time.zone.parse("14:59:59"))

    all_users = User
      .where("created_at < ?", args.end_date)

    total_users = all_users
      .count
    puts "All registrations to #{args.end_date}: \n#{total_users}\n\n"

    all_new_users = User
      .where("created_at BETWEEN ? AND ?", args.start_date, args.end_date)

    new_users = all_new_users
      .count
    puts "New registrations between #{args.start_date} and #{args.end_date}: \n#{new_users}\n\n"

    all_cookie_consent = all_users
      .pluck(:cookie_consent)
      .tally
    puts "Cookie consents to #{args.end_date}:\n"
    all_cookie_consent.each do |value, count|
      puts "#{value} #{count}"
    end
    puts "\n"

    new_cookie_consent = all_new_users
      .pluck(:cookie_consent)
      .tally
    puts "Cookie consents for registrations between #{args.start_date} and #{args.end_date}:\n"
    new_cookie_consent.each do |value, count|
      puts "#{value} #{count}"
    end
    puts "\n"

    all_feedback_consent = all_users
      .pluck(:feedback_consent)
      .tally
    puts "Feedback consents to #{args.end_date}:\n"
    all_feedback_consent.each do |value, count|
      puts "#{value} #{count}"
    end
    puts "\n"

    new_feedback_consent = all_new_users
      .pluck(:feedback_consent)
      .tally
    puts "Feedback consents for registrations between #{args.start_date} and #{args.end_date}:\n"
    new_feedback_consent.each do |value, count|
      puts "#{value} #{count}"
    end
    puts "\n"

    all_logins = SecurityActivity
      .where(event_type: "login")
      .where("created_at < ?", args.end_date)
    puts "Total number of logins to #{args.end_date}: \n#{all_logins.count}\n\n"

    interval_logins = all_logins
      .where("created_at BETWEEN ? AND ?", args.start_date, args.end_date)
    puts "Total number of logins between #{args.start_date} and #{args.end_date}: \n#{interval_logins.count}\n\n"

    all_user_logins = all_logins
      .pluck(:user_id)
      .uniq
    puts "Accounts logged in to #{args.end_date}: \n#{all_user_logins.count}\n\n"

    user_logins = interval_logins
      .pluck(:user_id)
      .uniq
    puts "Accounts logged in between #{args.start_date} and #{args.end_date}: \n#{user_logins.count}\n\n"

    all_login_frequency = SecurityActivity
      .where(event_type: "login")
      .where("created_at < ?", args.end_date)
      .pluck(:user_id)
      .tally
      .values
      .tally
      .sort
    puts "Number of logins per account to #{args.end_date}:\n"
    all_login_frequency.each do |frequency, count|
      puts "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}"
    end
    puts "\n"

    login_frequency = SecurityActivity
      .where(event_type: "login")
      .where("created_at BETWEEN ? AND ?", args.start_date, args.end_date)
      .pluck(:user_id)
      .tally
      .values
      .tally
      .sort
    puts "Number of logins between #{args.start_date} and #{args.end_date}:\n"
    login_frequency.each do |frequency, count|
      puts "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}"
    end
  end
end
