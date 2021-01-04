namespace :security do
  desc "Import the NCSC's password denylist.  This clears the current denylist."
  task import_ncsc_denylist: :environment do
    count = BannedPassword.import_from_ncsc
    puts "imported #{count} passwords"
  end

  desc "Check usage of passwords on the banned password list."
  task check_banned_password_usage: :environment do
    User.where(banned_password_match: nil).each do |user|
      UserBannedPasswordCheckJob.perform_later(user.id)
    end
  end
end
