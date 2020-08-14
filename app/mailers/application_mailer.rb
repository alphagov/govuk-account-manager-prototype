class ApplicationMailer < ActionMailer::Base
  self.delivery_job = NotifyDeliveryJob
end
