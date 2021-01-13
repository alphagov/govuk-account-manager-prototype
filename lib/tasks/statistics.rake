namespace :statistics do
  desc "Get information on all registrations and logins"
  task :general, %i[start_date end_date] => [:environment] do |_, args|
    args.with_defaults(start_date: Time.zone.parse("15:00:00") - 1.day, end_date: Time.zone.parse("15:00:00"))

    report = Report::GeneralStatistics.new(
      start_date: args.start_date,
      end_date: args.end_date,
    )

    puts report.humanize
  end
end
