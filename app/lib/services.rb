require "gds_api"

module Services
  def self.email_alert_api
    @email_alert_api ||= GdsApi.email_alert_api
  end
end
