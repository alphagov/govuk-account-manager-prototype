class AbTest
  extend Forwardable

  attr_reader :allowed_variants, :expires
  def_delegators :@ab_test, :ab_test_name, :dimension, :control_variant

  def initialize(ab_test_name, dimension:, expires: 1.day, allowed_variants: { A: 1, B: 1 }, control_variant: "A")
    @allowed_variants = allowed_variants.transform_keys(&:to_s)
    @ab_test = GovukAbTesting::AbTest.new(
      ab_test_name,
      dimension: dimension,
      allowed_variants: @allowed_variants.keys,
      control_variant: control_variant,
    )
    @frequency_sum = @allowed_variants.values.sum
    @expires = expires
  end

  def requested_variant(request, cookies, user = nil)
    cookie_consent = consented_to_testing(cookies, user)

    request_headers = {}
    request_headers[ab_test.request_header] =
      if cookie_consent
        find_or_assign_variant(request, cookies)
      else
        ab_test.control_variant
      end

    AbTest::RequestedVariant.new(
      self,
      cookie_consent,
      ab_test.requested_variant(request_headers),
    )
  end

  def cookie_name
    "ABTest-#{ab_test_name}"
  end

protected

  attr_reader :ab_test, :frequency_sum

  # A/B tests are only enabled for users who have consented to cookies
  def consented_to_testing(cookies, user)
    return user.cookie_consent if user

    JSON.parse(cookies.fetch(:cookies_policy, "null"))&.dig("usage")
  rescue JSON::ParserError
    false
  end

  # Simulate the variant assignment logic from govuk-cdn-config:
  #
  # 1. If the param ABTest-<name>=<variant> is set, use that
  # 2. If the cookie ABTest-<name>=<variant> is set, use that
  # 3. Otherwise bucket based on the variant frequencies
  def find_or_assign_variant(request, cookies)
    variant_from_request = request.params[cookie_name] || cookies[cookie_name]
    return variant_from_request if variant_from_request

    index = SecureRandom.random_number(frequency_sum)
    allowed_variants.each do |variant, freq|
      if index < freq
        return variant
      else
        index -= freq
      end
    end
  end

  class RequestedVariant
    extend Forwardable

    attr_reader :ab_test
    def_delegators :@requested_variant, :variant_name, :variant?, :analytics_meta_tag

    def initialize(ab_test, cookie_consent, requested_variant)
      @ab_test = ab_test
      @cookie_consent = cookie_consent
      @requested_variant = requested_variant
    end

    def configure_response(response, cookies)
      requested_variant.configure_response(response)

      if cookie_consent
        cookies[ab_test.cookie_name] = {
          value: variant_name,
          expires: ab_test.expires.from_now,
          secure: Rails.env.production?,
          path: "/",
        }
      end
    end

  protected

    attr_reader :cookie_consent, :requested_variant
  end
end
