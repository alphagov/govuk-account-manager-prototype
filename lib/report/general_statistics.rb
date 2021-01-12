module Report
  class GeneralStatistics
    def self.report(options)
      new(options).report
    end

    attr_reader :start_date, :end_date

    def initialize(start_date:, end_date:)
      @start_date = start_date
      @end_date = end_date
    end

    def report
      @report ||= {
        all: full_report(all_users, all_logins),
        interval: full_report(interval_users, interval_logins),
        start_date: start_date,
        end_date: end_date,
      }
    end

    def humanize
      [
        "Report up to #{@end_date}:",
        humanize_report(report[:all]),
        "",
        "Report between #{@start_date} and #{@end_date}:",
        humanize_report(report[:interval]),
      ].flatten.join("\n")
    end

  protected

    def full_report(users, logins)
      {
        users: {
          count: users.count,
          cookie_consents: users.pluck(:cookie_consent).tally,
          feedback_consents: users.pluck(:feedback_consent).tally,
        },
        logins: {
          count: logins.count,
          accounts: logins.pluck(:user_id).uniq.count,
          frequency: logins.pluck(:user_id).tally.values.tally.sort,
          frequency_ex_confirm: logins.where.not(analytics: "from_confirmation_email").pluck(:user_id).tally.values.tally.sort,
        },
      }
    end

    def humanize_report(data)
      output = []
      output << "  - all registrations: #{data[:users][:count]}"
      output << "  - cookie consents:"
      data[:users][:cookie_consents].each do |value, count|
        output << "    - #{value.to_s.humanize}: #{count}"
      end
      output << "  - feedback consents:"
      data[:users][:feedback_consents].each do |value, count|
        output << "    - #{value.to_s.humanize}: #{count}"
      end
      output << "  - total number of logins: #{data[:logins][:count]}"
      output << "  - accounts logged in to: #{data[:logins][:accounts]}"
      output << "  - number of logins per account:"
      data[:logins][:frequency].each do |frequency, count|
        output << "    - #{frequency} #{'time'.pluralize(frequency)}: #{count}"
      end
      output << "  - number of logins per account (excluding logins immediately after confirming email):"
      data[:logins][:frequency_ex_confirm].each do |frequency, count|
        output << "    - #{frequency} #{'time'.pluralize(frequency)}: #{count}"
      end

      output
    end

    def all_users
      User.where("created_at < ?", end_date)
    end

    def interval_users
      all_users.where("created_at >= ?", start_date)
    end

    def all_logins
      SecurityActivity
        .of_type(SecurityActivity::LOGIN_SUCCESS)
        .where(oauth_application_id: nil)
        .where("created_at < ?", end_date)
    end

    def interval_logins
      all_logins.where("created_at >= ?", start_date)
    end
  end
end
