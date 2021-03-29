require "rake_helper"

RSpec.describe "Email tasks" do
  include ActiveJob::TestHelper
  before { clear_enqueued_jobs }

  describe ":count_survey_recipients" do
    subject(:task) { Rake.application["emails:count_2021_03_survey_recipients"] }

    context "When no-one has recieved a survey" do
      it "outputs zero users have recieved a survey" do
        expect { task.invoke }.to output("Number of 2021_03_survey already sent: 0\n").to_stdout
      end
    end

    context "When a user has recieved a survey" do
      before do
        FactoryBot.create(:user, :confirmed, :has_received_2021_03_survey, email: "user@gov.uk")
      end

      it "outputs 1 user has recieved a survey" do
        expect { task.invoke }.to output("Number of 2021_03_survey already sent: 1\n").to_stdout
      end
    end
  end

  describe ":send_survey_by_login_cohorts" do
    subject(:task) { Rake.application["emails:send_2021_03_survey_by_login_cohorts"] }

    context "With no users" do
      it "tells the user it has not sent any emails" do
        expect {
          task.invoke(10, 10, 10)
        }.to output(
          "10 minute group: 0\n" \
          "1 minute group: 0\n" \
          "Remaining group: 0\n" \
          "Total: 0 users will be sent the 2021_03_survey\n",
        ).to_stdout
      end
    end

    context "With no consenting users" do
      before do
        3.times do |n|
          FactoryBot.create(:user, :confirmed, email: "user#{n}@gov.uk", feedback_consent: false)
        end
      end

      it "tells the user it has not sent any emails" do
        expect {
          task.invoke(10, 10, 10)
        }.to output(
          "10 minute group: 0\n" \
          "1 minute group: 0\n" \
          "Remaining group: 0\n" \
          "Total: 0 users will be sent the 2021_03_survey\n",
        ).to_stdout
      end
    end

    context "With two users who have consented and one who has not" do
      before do
        2.times do |n|
          FactoryBot.create(:user, :confirmed, :has_not_received_2021_03_survey, email: "user#{n}@gov.uk", feedback_consent: true)
        end

        FactoryBot.create(:user, :confirmed, :has_not_received_2021_03_survey, email: "user3@gov.uk", feedback_consent: false)
      end

      it "should exclude users who have not consented" do
        expect {
          task.invoke(10, 10, 10)
        }.to output(
          "10 minute group: 0\n" \
          "1 minute group: 0\n" \
          "Remaining group: 2\n" \
          "Total: 2 users will be sent the 2021_03_survey\n",
        ).to_stdout
      end
    end

    context "With three consenting users who have already recieved the survey and four that have not" do
      before do
        3.times do |n|
          FactoryBot.create(:user, :confirmed, :has_received_2021_03_survey, email: "user#{n}@gov.uk", feedback_consent: true)
        end

        4.times do |n|
          n += 4
          FactoryBot.create(:user, :confirmed, :has_not_received_2021_03_survey, email: "user#{n}@gov.uk", feedback_consent: true)
        end
      end

      it "should exclude users that have already recieved the survey" do
        expect {
          task.invoke(10, 10, 10)
        }.to output(
          "10 minute group: 0\n" \
          "1 minute group: 0\n" \
          "Remaining group: 4\n" \
          "Total: 4 users will be sent the 2021_03_survey\n",
        ).to_stdout
      end
    end

    context "With users who last_sign_in_at only logged in after creating an account and others with more recent logins" do
      before do
        3.times do |n|
          FactoryBot.create(
            :user,
            :confirmed,
            :has_not_received_2021_03_survey,
            email: "user#{n}@gov.uk",
            feedback_consent: true,
            last_sign_in_at: Time.zone.now,
            created_at: 2.minutes.ago,
          )
        end

        4.times do |n|
          n += 4
          FactoryBot.create(
            :user,
            :confirmed,
            :has_not_received_2021_03_survey,
            email: "user#{n}@gov.uk",
            feedback_consent: true,
          )
        end
      end

      it "separates out users who last signed in immediately after creating an account" do
        expect {
          task.invoke(10, 10, 10)
        }.to output(
          "10 minute group: 0\n" \
          "1 minute group: 3\n" \
          "Remaining group: 4\n" \
          "Total: 7 users will be sent the 2021_03_survey\n",
        ).to_stdout
      end
    end

    context "With users in all three created time cohorts" do
      before do
        20.times do |n|
          FactoryBot.create(
            :user,
            :confirmed,
            :has_not_received_2021_03_survey,
            email: "user#{n}@gov.uk",
            feedback_consent: true,
            last_sign_in_at: Time.zone.now,
            created_at: 15.minutes.ago,
          )
        end

        40.times do |n|
          n += 20
          FactoryBot.create(
            :user,
            :confirmed,
            :has_not_received_2021_03_survey,
            email: "user#{n}@gov.uk",
            feedback_consent: true,
            last_sign_in_at: Time.zone.now,
            created_at: 2.minutes.ago,
          )
        end

        20.times do |n|
          n += 60
          FactoryBot.create(
            :user,
            :confirmed,
            :has_not_received_2021_03_survey,
            email: "user#{n}@gov.uk",
          )
        end
      end

      it "separates out users who created an account within the last minute" do
        expect {
          task.invoke(20, 20, 20)
        }.to output(
          "10 minute group: 20\n" \
          "1 minute group: 20\n" \
          "Remaining group: 20\n" \
          "Total: 60 users will be sent the 2021_03_survey\n",
        ).to_stdout
      end

      it "should constrain results to the limits it is passed" do
        expect {
          task.invoke(1, 2, 3)
        }.to output(
          "10 minute group: 1\n" \
          "1 minute group: 2\n" \
          "Remaining group: 3\n" \
          "Total: 6 users will be sent the 2021_03_survey\n",
        ).to_stdout
      end
    end
  end
end
