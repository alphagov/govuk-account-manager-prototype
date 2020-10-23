module Healthcheck
  def self.check
    checks = {
      database_connectivity: { status: check_database },
      redis_connectivity: { status: check_redis },
    }

    {
      status: checks.values.any? { |check| check[:status] == :critical } ? :critical : :ok,
      checks: checks,
    }
  end

  def self.check_database
    ::ActiveRecord::Base.connection
    :ok
  rescue StandardError
    :critical
  end

  def self.check_redis
    Sidekiq.redis_info ? :ok : :critical
  rescue StandardError
    :critical
  end
end
