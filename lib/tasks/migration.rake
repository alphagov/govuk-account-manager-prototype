namespace :migration do
  desc "Persist subject identifiers for all users without them already saved"
  task persist_missing_subject_identifiers: :environment do
    users = User.where(subject_identifier: nil)
    total = users.count
    done = 0
    users.find_each do |user|
      user.generate_subject_identifier
      done += 1
      puts "Progress: #{done} / #{total}" if (done % 100).zero?
    end
  end

  desc "Send cookie & feedback consents to account-api"
  task send_consents_to_account_api: :environment do
    total = Users.count
    done = 0
    users.find_each do |user|
      GdsApi.account_api.update_user_by_subject_identifier(
        subject_identifier: user.generate_subject_identifier,
        cookie_consent: user.cookie_consent,
        feedback_consent: user.feedback_consent,
      )
      done += 1
      puts "Progress: #{done} / #{total}" if (done % 100).zero?
    end
  end
end
