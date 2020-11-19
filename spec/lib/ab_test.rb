RSpec.describe AbTest do
  include ActiveSupport::Testing::TimeHelpers

  let(:ab_test) { AbTest.new("Test", dimension: 999, allowed_variants: { A: 1, B: 1, C: 1 }) }

  describe "#requested_variant" do
    let(:request) do
      ActionDispatch::Request.empty.tap { |request| request.request_parameters = request_parameters }
    end
    let(:request_parameters) { {} }
    let(:cookies) { { "ABTest-Test" => "B" } }
    let(:user) { nil }

    let(:requested_variant) { ab_test.requested_variant(request, cookies.with_indifferent_access, user) }

    it "assigns the control variant" do
      expect(requested_variant.variant_name).to eq("A")
    end

    it "sets the Vary header" do
      response = double(headers: {})
      requested_variant.configure_response(response, {})
      expect(response.headers["Vary"]).to eq("GOVUK-ABTest-Test")
    end

    it "does not set the response cookie" do
      cookies = {}
      requested_variant.configure_response(double(headers: {}), cookies)
      expect(cookies).to eq({})
    end

    context "the user has a policy cookie with consent" do
      let(:cookies) { { "ABTest-Test" => "B", "cookies_policy" => "{\"usage\":true}" } }

      it "assigns the specified variant" do
        expect(requested_variant.variant_name).to eq("B")
      end

      it "sets the response cookie" do
        freeze_time do
          cookies = {}
          requested_variant.configure_response(double(headers: {}), cookies)
          expect(cookies.dig("ABTest-Test", :value)).to eq(requested_variant.variant_name)
          expect(cookies.dig("ABTest-Test", :expires)).to eq(ab_test.expires.from_now)
        end
      end
    end

    context "the user is logged in" do
      let(:user) do
        double(cookie_consent: cookie_consent, ab_test_test: account_variant).tap do |user|
          allow(user).to receive(:update!)
        end
      end

      let(:account_variant) { nil }
      let(:cookie_consent) { false }

      it "assigns the control variant" do
        expect(requested_variant.variant_name).to eq("A")
      end

      it "does not set the response cookie" do
        cookies = {}
        requested_variant.configure_response(double(headers: {}), cookies)
        expect(cookies).to eq({})
      end

      context "the user has consent enabled in their account" do
        let(:cookie_consent) { true }

        it "assigns the specified variant" do
          expect(requested_variant.variant_name).to eq("B")
        end

        it "persists the variant in the account" do
          expect(user).to receive(:update!).with(ab_test_test: "B")
          requested_variant
        end

        it "sets the response cookie" do
          freeze_time do
            cookies = {}
            requested_variant.configure_response(double(headers: {}), cookies)
            expect(cookies.dig("ABTest-Test", :value)).to eq(requested_variant.variant_name)
            expect(cookies.dig("ABTest-Test", :expires)).to eq(ab_test.expires.from_now)
          end
        end

        context "the user has a variant saved in their account" do
          let(:account_variant) { "C" }

          it "assigns the persisted variant" do
            expect(user).to receive(:update!).with(ab_test_test: "C")
            requested_variant
          end
        end
      end
    end
  end
end
