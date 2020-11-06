require "notifications/client"

class NotifySmsDeliveryJob < ApplicationJob
  queue_as :mailers

  discard_on Notifications::Client::BadRequestError

  retry_on(
    Notifications::Client::RequestError,
    wait: :exponentially_longer,
    attempts: 5,
  )

  def perform(phone_number, body)
    Notifications::Client.new(Rails.application.secrets.notify_api_key).send_sms(
      phone_number: TelephoneNumber.parse(phone_number, :gb).e164_number,
      template_id: ENV.fetch("GOVUK_NOTIFY_SMS_TEMPLATE_ID"),
      personalisation: {
        body: body,
      },
    )
  end
end
