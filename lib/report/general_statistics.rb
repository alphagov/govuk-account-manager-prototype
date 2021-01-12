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
      output = ""

      output += "All registrations to #{@end_date}: \n#{report[:all][:users][:count]}\n\n"
      output += "New registrations between #{@start_date} and #{@end_date}: \n#{report[:interval][:users][:count]}\n\n"

      output += "Cookie consents to #{@end_date}:\n"
      report[:all][:users][:cookie_consents].each do |value, count|
        output += "#{value.to_s.humanize} #{count}\n"
      end
      output += "\n"

      output += "Cookie consents for registrations between #{@start_date} and #{@end_date}:\n"
      report[:interval][:users][:cookie_consents].each do |value, count|
        output += "#{value.to_s.humanize} #{count}\n"
      end
      output += "\n"

      output += "Feedback consents to #{@end_date}:\n"
      report[:all][:users][:feedback_consents].each do |value, count|
        output += "#{value.to_s.humanize} #{count}\n"
      end
      output += "\n"

      output += "Feedback consents for registrations between #{@start_date} and #{@end_date}:\n"
      report[:interval][:users][:feedback_consents].each do |value, count|
        output += "#{value.to_s.humanize} #{count}\n"
      end
      output += "\n"

      output += "Total number of logins to #{@end_date}: \n#{report[:all][:logins][:count]}\n\n"

      output += "Total number of logins between #{@start_date} and #{@end_date}: \n#{report[:interval][:logins][:count]}\n\n"

      output += "Accounts logged in to #{@end_date}: \n#{report[:all][:logins][:accounts]}\n\n"

      output += "Accounts logged in between #{@start_date} and #{@end_date}: \n#{report[:all][:logins][:accounts]}\n\n"

      output += "Number of logins per account to #{@end_date}:\n"
      report[:all][:logins][:frequency].each do |frequency, count|
        output += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
      end
      output += "\n"

      output += "Number of logins between #{@start_date} and #{@end_date}:\n"
      report[:interval][:logins][:frequency].each do |frequency, count|
        output += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
      end

      output += "Number of logins per account to #{@end_date} (excluding logins immediately after confirming email):\n"
      report[:all][:logins][:frequency_ex_confirm].each do |frequency, count|
        output += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
      end
      output += "\n"

      output += "Number of logins between #{@start_date} and #{@end_date} (excluding logins immediately after confirming email):\n"
      report[:interval][:logins][:frequency_ex_confirm].each do |frequency, count|
        output += "Accounts logged into #{frequency} #{'time'.pluralize(frequency)}: #{count}\n"
      end

      output
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
