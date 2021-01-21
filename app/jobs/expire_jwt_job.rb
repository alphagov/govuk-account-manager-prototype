class ExpireJwtJob < ApplicationJob
  queue_as :default

  def perform
    Jwt.expired.delete_all
  end
end
