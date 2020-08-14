class NotifyDeliveryJob < ActionMailer::DeliveryJob
  queue_as :mailers

  discard_on Notifications::Client::BadRequestError

  retry_on(
    Notifications::Client::RequestError,
    wait: :exponentially_longer,
    attempts: 5,
  )
end
