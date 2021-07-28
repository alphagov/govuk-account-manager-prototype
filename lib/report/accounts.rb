module Report
  class Accounts
    def initialize(user_id_pepper:)
      @user_id_pepper = user_id_pepper
    end

    def all
      User.all.map { |user| user_to_row(user) }.compact
    end

    def in_batches(batch_size: 200)
      User.find_in_batches(batch_size: batch_size) do |batch|
        rows = batch.map { |user| user_to_row(user) }.compact
        yield rows
      end
    end

  protected

    attr_reader :user_id_pepper

    def user_to_row(user)
      return if user.email == Report::SMOKEY_USER

      {
        user_id: hashed_id(user.id),
        registration_timestamp: user.created_at,
        cookie_consent: user.cookie_consent,
        feedback_consent: user.feedback_consent,
      }
    end

    def hashed_id(user_id)
      Digest::SHA256.hexdigest("#{user_id}#{user_id_pepper}")
    end
  end
end
