RSpec.describe SecurityActivity do
  let(:event) { SecurityActivity::LOGIN_SUCCESS }
  let(:event_type) { event&.id }

  let(:user) { FactoryBot.create(:user) }
  let(:user_id) { user&.id }

  let(:ip_address) { "127.0.0.1" }

  let(:factor) { nil }

  context "validations" do
    let(:activity) { SecurityActivity.new(event_type: event_type, user_id: user_id, ip_address: ip_address, factor: factor) }

    it "is valid with an event_type, user_id, and ip_address" do
      expect(activity).to be_valid
    end

    context "without an event_type" do
      let(:event_type) { nil }

      it "is invalid" do
        expect(activity).to_not be_valid
      end
    end

    context "with a bad event_type" do
      let(:event_type) { 999_999 }

      it "is invalid" do
        expect(activity).to_not be_valid
      end
    end

    context "without a user_id" do
      let(:user_id) { nil }

      it "is invalid" do
        expect(activity).to_not be_valid
      end
    end

    context "without an IP address" do
      let(:ip_address) { nil }

      it "is invalid" do
        expect(activity).to_not be_valid
      end

      context "the event doesn't require an IP address" do
        let(:event) { SecurityActivity::ACCOUNT_LOCKED }

        it "is valid" do
          expect(activity).to be_valid
        end
      end
    end

    context "the event requires a factor" do
      let(:event) { SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_SUCCESS }

      it "is invalid" do
        expect(activity).to_not be_valid
      end

      context "with a good factor" do
        let(:factor) { :sms }

        it "is valid" do
          expect(activity).to be_valid
        end
      end

      context "with a bad factor" do
        let(:factor) { :smoke_signals }

        it "is invalid" do
          expect(activity).to_not be_valid
        end
      end
    end
  end

  context "#event" do
    let(:activity) { SecurityActivity.new(event_type: event_type, user_id: user_id, ip_address: ip_address) }

    it "returns the correct event" do
      expect(activity.event).to eq(event)
    end
  end

  context "#client" do
    let(:application) { FactoryBot.create(:oauth_application, name: "name", redirect_uri: "http://localhost/") }
    let(:activity) { SecurityActivity.new(event_type: event_type, user_id: user_id, ip_address: ip_address, oauth_application_id: application&.id) }

    it "returns the provided OAuth application name" do
      expect(activity.client).to eq(application.name)
    end

    context "without an oauth_application_id" do
      let(:application) { nil }

      it "returns the default application name" do
        expect(activity.client).to eq(AccountManagerApplication::NAME)
      end
    end
  end

  context "#to_hash" do
    let(:notes) { "notes" }
    let(:activity) { SecurityActivity.create!(event_type: event_type, user_id: user_id, ip_address: ip_address, notes: notes) }

    it "includes the event type" do
      expect(activity.to_hash[:action]).to eq(event.name)
    end

    it "includes the creation time" do
      expect(activity.to_hash[:timestamp]).to eq(activity.created_at.utc)
    end

    it "doesn't include any PII" do
      activity.to_hash.each_value do |v|
        expect(v.to_s).to_not include(notes)
        expect(v.to_s).to_not include(user.email)
        expect(v.to_s).to_not include(user.phone)
      end
    end
  end

  context "#record_event" do
    let(:user_agent_name) { "user-agent-name" }
    let(:activity) { SecurityActivity.record_event(SecurityActivity::LOGIN_SUCCESS, user: user, ip_address: ip_address, user_agent_name: user_agent_name) }

    it "constructs a valid event" do
      expect(activity.valid?).to be(true)
    end

    it "saves the user-agent to the database" do
      expect(activity.user_agent&.name).to eq(user_agent_name)
    end
  end

  context "#of_type" do
    it "filters the events" do
      SecurityActivity.record_event(SecurityActivity::LOGIN_SUCCESS, user: user, ip_address: ip_address)
      SecurityActivity.record_event(SecurityActivity::LOGIN_SUCCESS, user: user, ip_address: ip_address)
      SecurityActivity.record_event(SecurityActivity::LOGIN_SUCCESS, user: user, ip_address: ip_address)
      SecurityActivity.record_event(SecurityActivity::LOGIN_FAILURE, user: user, ip_address: ip_address)

      expect(SecurityActivity.of_type(SecurityActivity::LOGIN_SUCCESS).count).to be(3)
      expect(SecurityActivity.of_type(SecurityActivity::LOGIN_FAILURE).count).to be(1)
    end
  end
end
