module Report
  class AccountEvents
    SESSION_DURATION = 5.hours

    attr_reader :start_date, :end_date

    def initialize(start_date:, end_date:, user_id_pepper:)
      @start_date = start_date
      @end_date = end_date
      @user_id_pepper = user_id_pepper
      @previous_login_times = {}
    end

    def all
      all_login_events_in_report
        .map { |activity| to_login_event(activity) }
    end

    def in_batches(batch_size: 200)
      all_login_events_in_report.find_in_batches(batch_size: batch_size) do |batch|
        rows = batch.map { |activity| to_login_event(activity) }
        yield rows
      end
    end

  protected

    attr_reader :user_id_pepper, :previous_login_times

    def to_login_event(activity)
      previous_login_time = previous_login_times[activity.user_id] || find_previous_login_time(activity.user_id, activity.created_at)
      previous_login_times[activity.user_id] = activity.created_at

      {
        user_id: hashed_id(activity.user_id),
        login_timestamp: activity.created_at,
        login_type: login_type_from_timestamps(activity.created_at, previous_login_time),
      }
    end

    def find_previous_login_time(user_id, before_time)
      all_login_events.where(user_id: user_id)
        .where("created_at < ?", before_time)
        .last&.created_at
    end

    def login_type_from_timestamps(current_login_time, previous_login_time)
      return :account unless previous_login_time

      return :session if current_login_time - previous_login_time < SESSION_DURATION

      :returning
    end

    def all_login_events
      SecurityActivity
        .of_type(SecurityActivity::LOGIN_SUCCESS)
        .where(oauth_application_id: nil)
        .where("created_at < ?", end_date)
        .order(:created_at)
    end

    def all_login_events_in_report
      all_login_events
        .where("created_at >= ?", start_date)
    end

    def hashed_id(user_id)
      Digest::SHA256.hexdigest("#{user_id}#{user_id_pepper}")
    end
  end
end
