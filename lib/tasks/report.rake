require "csv"

namespace :report do
  desc "Report on accounts."
  task accounts: [:environment] do
    CSV($stdout, write_headers: true, headers: %i[user_id registration_timestamp cookie_consent feedback_consent]) do |csv|
      Report::Accounts.report(
        user_id_pepper: Rails.application.secrets.reporting_user_id_pepper,
      ).each do |event|
        csv << event
      end
    end
  end

  desc "Report on account events."
  task :account_events, %i[start_date end_date] => [:environment] do |_, args|
    CSV($stdout, write_headers: true, headers: %i[user_id login_timestamp login_type]) do |csv|
      Report::AccountEvents.report(
        start_date: args[:start_date],
        end_date: args[:end_date],
        user_id_pepper: Rails.application.secrets.reporting_user_id_pepper,
      ).each do |event|
        csv << event
      end
    end
  end
end
