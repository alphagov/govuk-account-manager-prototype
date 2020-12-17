RSpec.describe DataActivity do
  include ActiveSupport::Testing::TimeHelpers

  let(:user1) { FactoryBot.create(:user, email: "user1@example1.com") }
  let(:user2) { FactoryBot.create(:user, email: "user2@example1.com") }
  let(:user3) { FactoryBot.create(:user, email: "user3@example1.com") }

  let(:application1) { FactoryBot.create(:oauth_application, name: "one", redirect_uri: "http://localhost/") }
  let(:application2) { FactoryBot.create(:oauth_application, name: "two", redirect_uri: "http://localhost/") }
  let(:application3) { FactoryBot.create(:oauth_application, name: "three", redirect_uri: "http://localhost/") }

  context "#very_similar_to" do
    it "is reflexive" do
      25.times do
        act = random_activity

        expect(act.very_similar_to(act)).to be(true)
      end
    end

    it "is commutative" do
      25.times do
        act1 = random_activity
        act2 = random_activity

        expect(act1.very_similar_to(act2)).to eq(act2.very_similar_to(act1))
      end
    end

    it "is only similar if the users are the same" do
      25.times do
        act1 = random_activity(user: user1)
        act2 = random_activity(user: user2)

        expect(act1.very_similar_to(act2)).to be(false)
      end
    end

    it "is only similar if the applications are the same" do
      25.times do
        act1 = random_activity(oauth_application: application1)
        act2 = random_activity(oauth_application: application2)

        expect(act1.very_similar_to(act2)).to be(false)
      end
    end

    it "is only similar if the creation times are within a minute" do
      25.times do
        time1 = Time.zone.now
        time2 = time1 + 61.seconds

        act1 = random_activity(created_at: time1)
        act2 = random_activity(created_at: time2)

        expect(act1.very_similar_to(act2)).to be(false)
      end
    end
  end

  def random_activity(options = {})
    DataActivity.new(
      {
        user: [user1, user2, user3].sample,
        oauth_application: [application1, application2, application3].sample,
        created_at: rand(5.minutes.to_i).seconds.ago,
      }.merge(options),
    )
  end
end
