module Report
  class Accounts
    def self.report(options)
      new(options).report
    end

    def initialize(user_id_pepper:)
      @user_id_pepper = user_id_pepper
    end

    def report
      User.order(:created_at).map do |user|
        {
          user_id: hashed_id(user.id),
          registration_timestamp: user.created_at,
          cookie_consent: user.cookie_consent,
          feedback_consent: user.feedback_consent,
        }
      end
    end

  protected

    attr_reader :user_id_pepper

    def hashed_id(user_id)
      Digest::SHA256.hexdigest("#{user_id}#{user_id_pepper}")
    end
  end
end
