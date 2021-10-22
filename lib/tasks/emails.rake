namespace :emails do
  desc "Send the downtime notice to users"
  task downtime: :environment do
    users = User.where(has_received_downtime_email: false)
    total = users.count
    done = 0

    first_slice = true
    users.each_slice(2500) do |slice|
      if first_slice
        first_slice = false
      else
        puts "pausing for 60 seconds"
        sleep 60
      end

      slice.each do |user|
        confirmed = user.confirmed_at.present?

        UserMailer.with(
          email: user.email,
          subject: downtime_email_subject(confirmed: confirmed),
          body: downtime_email_body(confirmed: confirmed),
        ).adhoc_email.deliver_later

        user.update!(has_received_downtime_email: true)

        done += 1
        puts "Progress: #{done} / #{total}" if (done % 100).zero?
      end
    end
  end

  desc "Send the downtime email to a test address"
  task :test_downtime, %i[email] => [:environment] do |_, args|
    abort("Please provide an email") if args.email.nil?

    UserMailer.with(
      email: args.email,
      subject: downtime_email_subject(confirmed: false),
      body: downtime_email_body(confirmed: false),
    ).adhoc_email.deliver_later

    UserMailer.with(
      email: args.email,
      subject: downtime_email_subject(confirmed: true),
      body: downtime_email_body(confirmed: true),
    ).adhoc_email.deliver_later
  end
end

def downtime_email_subject(confirmed:)
  if confirmed
    "You will not be able to update your GOV.UK account details from 25 to 27 October"
  else
    "Confirm the email address for your GOV.UK account by 25 October"
  end
end

def downtime_email_body(confirmed:)
  if confirmed
    <<~BODY
      Hello

      We’re making a few changes to how you sign in to your GOV.UK account. These changes will happen next week between 25 and 27 October.

      # What this means for you

      You’ll still be able to sign in to your GOV.UK account during this time, but you will not be able update your account details, including your:

      - email address
      - mobile phone number
      - password

      If you want to update your account details, you’ll need to do this before 9am on 25 October. Otherwise, you’ll have to wait until 5pm on 27 October to make the updates.

      Sign in to manage your GOV.UK account: https://www.account.publishing.service.gov.uk/sign-in

      # Changes from 27 October

      Your account will look a little different and there will be a few changes to the way you sign in.

      You’ll have to enter your password the first time you sign in after 5pm on 27 October, even if you’ve saved your password in your browser. This is to make sure your account stays secure.

      If you sign in to see your answers to the Brexit checker, you’ll also have to enter a security code that we’ll send to your mobile phone.

      # Why we’re making these changes

      These changes will make it easier for other government services to connect to GOV.UK accounts. This will help us get closer to the goal of a single account where you can access all your government services.

      If you have any questions, you can contact us: https://www.account.publishing.service.gov.uk/feedback

      Best wishes
      The GOV.UK account team
    BODY
  else
    <<~BODY
      Hello

      We’re making a few changes to how you sign in to your GOV.UK account. These changes will happen next week between 25 and 27 October.

      # Confirm your email address now

      You need to confirm the email address for your GOV.UK account before 9am on 25 October.

      If you do not confirm your email address by this time, your account and all the information stored in it will be deleted.

      Confirm your email address: https://www.account.publishing.service.gov.uk/account/confirmation/new

      # If you want to update your account details

      You’ll still be able to sign in to your GOV.UK account between 25 and 27 October, but you will not be able to update any of your account details, including your:

      - email address
      - mobile phone number
      - password

      If you want to update your account details, you need to do this before 9am on 25 October. Otherwise, you’ll have to wait until 5pm on 27 October to make the updates.

      Sign in to manage your GOV.UK account: https://www.account.publishing.service.gov.uk/sign-in

      # Changes from 27 October

      Your account will look a little different and there will be a few changes to the way you sign in.

      You’ll have to enter your password the first time you sign in after 5pm on 27 October, even if you’ve saved your password in your browser. This is to make sure your account stays secure.

      If you sign in to see your answers to the Brexit checker, you’ll also have to enter a security code that we’ll send to your mobile phone.

      # Why we’re making these changes

      These changes will make it easier for other government services to connect to GOV.UK accounts. This will help us get closer to the goal of a single account where you can access all your government services.

      If you have any questions, you can contact us: https://www.account.publishing.service.gov.uk/feedback

      Best wishes
      The GOV.UK account team
    BODY
  end
end
