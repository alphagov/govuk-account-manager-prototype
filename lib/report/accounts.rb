module Report
  class Accounts
    def initialize(user_id_pepper:)
      @user_id_pepper = user_id_pepper
    end

    def all
      all_users.map { |user| user_to_row(user) }
    end

    def in_batches(batch_size: 200)
      all_users.find_in_batches(batch_size: batch_size) do |batch|
        rows = batch.map { |user| user_to_row(user) }
        yield rows
      end
    end

  protected

    attr_reader :user_id_pepper

    def user_to_row(user)
      {
        user_id: hashed_id(user.id),
        registration_timestamp: user.created_at,
        cookie_consent: user.cookie_consent,
        feedback_consent: user.feedback_consent,
      }
    end

    def all_users
      User.order(:created_at)
    end

    def hashed_id(user_id)
      Digest::SHA256.hexdigest("#{user_id}#{user_id_pepper}")
    end
  end
end
