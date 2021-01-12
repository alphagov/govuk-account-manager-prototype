namespace :statistics do
  desc "Get information on all registrations and logins"
  task :general, %i[start_date end_date] => [:environment] do |_, args|
    args.with_defaults(start_date: Time.zone.parse("15:00:00") - 1.day, end_date: Time.zone.parse("15:00:00"))

    report = Report::GeneralStatistics.report(
      start_date: args.start_date,
      end_date: args.end_date,
    )

    results = ""

    results += "All registrations to #{args.end_date}: \n#{report[:all][:users][:count]}\n\n"
    results += "New registrations between #{args.start_date} and #{args.end_date}: \n#{report[:interval][:users][:count]}\n\n"

    results += "Cookie consents to #{args.end_date}:\n"
    report[:all][:users][:cookie_consents].each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    results += "Cookie consents for registrations between #{args.start_date} and #{args.end_date}:\n"
    report[:interval][:users][:cookie_consents].each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    results += "Feedback consents to #{args.end_date}:\n"
    report[:all][:users][:feedback_consents].each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    results += "Feedback consents for registrations between #{args.start_date} and #{args.end_date}:\n"
    report[:interval][:users][:feedback_consents].each do |value, count|
      results += "#{value.to_s.humanize} #{count}\n"
    end
    results += "\n"

    results += "Total number of logins to #{args.end_date}: \n#{report[:all][:logins][:count]}\n\n"

    results += "Total number of logins between #{args.start_date} and #{args.end_date}: \n#{report[:interval][:logins][:count]}\n\n"

    results += "Accounts logged in to #{args.end_date}: \n#{report[:all][:logins][:accounts]}\n\n"

    results += "Accounts logged in between #{args.start_date} and #{args.end_date}: \n#{report[:all][:logins][:accounts]}\n\n"

    results += "Number of logins per account to #{args.end_date}:\n"
    report[:all][:logins][:frequency].each do |frequency, count|
      results += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
    end
    results += "\n"

    results += "Number of logins between #{args.start_date} and #{args.end_date}:\n"
    report[:interval][:logins][:frequency].each do |frequency, count|
      results += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
    end

    results += "Number of logins per account to #{args.end_date} (excluding logins immediately after confirming email):\n"
    report[:all][:logins][:frequency_ex_confirm].each do |frequency, count|
      results += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
    end
    results += "\n"

    results += "Number of logins between #{args.start_date} and #{args.end_date} (excluding logins immediately after confirming email):\n"
    report[:interval][:logins][:frequency_ex_confirm].each do |frequency, count|
      results += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
    end

    output = [{
      title: "Daily Statistics",
      text: results,
    }]

    puts output.to_json
  end
end
