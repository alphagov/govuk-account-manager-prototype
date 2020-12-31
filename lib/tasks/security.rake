namespace :security do
  desc "Import the NCSC's password denylist.  This clears the current denylist."
  task import_ncsc_denylist: :environment do
    count = BannedPassword.import_from_ncsc
    puts "imported #{count} passwords"
  end
end
