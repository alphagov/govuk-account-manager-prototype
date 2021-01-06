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
      {
        all: full_report(all_users, all_logins),
        interval: full_report(interval_users, interval_logins),
      }
    end

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

  protected

    def all_users
      User.where("created_at < ?", end_date)
    end

    def interval_users
      all_users.where("created_at BETWEEN ? AND ?", start_date, end_date)
    end

    def all_logins
      SecurityActivity
        .of_type(SecurityActivity::LOGIN_SUCCESS)
        .where(oauth_application_id: nil)
        .where("created_at < ?", end_date)
    end

    def interval_logins
      all_logins.where("created_at BETWEEN ? AND ?", start_date, end_date)
    end
  end
end
