namespace :emails do
  desc "Count the number of users who have received a survey"
  task :count_2021_03_survey_recipients, %i[] => [:environment] do |_, _args|
    survery_count = User.where(has_received_2021_03_survey: true).count
    puts "Number of 2021_03_survey already sent: #{survery_count}"
  end

  desc "send test email"
  task :test_email, %i[email] => [:environment] do |_, args|
    abort("Please provide an email") if args.email.nil?

    UserMailer.with(
      email: args.email,
      subject: default_email_subject_line,
      body: default_email_body,
    ).adhoc_email.deliver_later
  end

  desc "Send a survey to user groups in cohorts of most recently logged in"
  task :send_2021_03_survey_by_login_cohorts,
       %i[ten_minute_group_limit one_minute_group_limit remaining_group_limit] => [:environment] do |_, args|
    args.with_defaults(
      ten_minute_group_limit: 50,
      one_minute_group_limit: 100,
      remaining_group_limit: 350,
    )

    previously_sent = User.where(has_received_2021_03_survey: true).count

    ten_minute_group = User.where(feedback_consent: true, has_received_2021_03_survey: false)
                           .where("last_sign_in_at > created_at + interval '10 minute'")
                           .order(Arel.sql("RANDOM()"))
                           .limit(args.ten_minute_group_limit)
                           .to_a

    puts "10 minute group: #{ten_minute_group.count}"
    ten_minute_group.map { |user| user.update!(has_received_2021_03_survey: true) }

    one_minute_group = User.where(feedback_consent: true, has_received_2021_03_survey: false)
                           .where("last_sign_in_at > created_at + interval '1 minute'")
                           .order(Arel.sql("RANDOM()"))
                           .limit(args.one_minute_group_limit)
                           .to_a

    puts "1 minute group: #{one_minute_group.count}"
    one_minute_group.map { |user| user.update!(has_received_2021_03_survey: true) }

    remaining_group = User.where(feedback_consent: true, has_received_2021_03_survey: false)
                          .order(Arel.sql("RANDOM()"))
                          .limit(args.remaining_group_limit)
                          .to_a

    puts "Remaining group: #{remaining_group.count}"
    remaining_group.map { |user| user.update!(has_received_2021_03_survey: true) }

    users = [ten_minute_group, one_minute_group, remaining_group].flatten.uniq

    puts "Total: #{users.count} users will be sent the 2021_03_survey"
    first_slice = true
    users.each_slice(2500) do |slice|
      sleep 60 unless first_slice
      first_slice = false

      slice.each do |user|
        UserMailer.with(
          email: user.email,
          subject: default_email_subject_line,
          body: default_email_body,
        ).adhoc_email.deliver_later
      end
    end
    puts "User emails have been enqueued"
    puts "Previous Total has_received_2021_03_survey: #{previously_sent}"
    puts "New Total has_received_2021_03_survey: #{User.where(has_received_2021_03_survey: true).count}"
  end
end

def default_email_subject_line
  "What do you think about your GOV.UK account?"
end

def default_email_body
  "Hello

  You recently created a GOV.UK account when you used the Brexit checker to find out about new rules for Brexit.

  The GOV.UK Account team would like to know what you think about your account.

  Please fill in this short feedback survey:
  https://surveys.publishing.service.gov.uk/s/account-feedback2/

  It’s 5 questions long and should only take around 5 minutes to complete.

  Your feedback will help us understand what improvements we need to make to your GOV.UK account and what new features we should add to it next.


  Many thanks
  GOV.UK Account team



  Do not reply to this email. If you do, your reply will go to an unmonitored account.

  You’ve received this email because the settings on your GOV.UK account say GOV.UK can email you to ask for feedback. If you do not want to get these emails, you can sign in to your account and change your feedback settings: https://www.account.publishing.service.gov.uk/sign-in
  "
end
