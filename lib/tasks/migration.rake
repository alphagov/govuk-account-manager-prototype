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
end
