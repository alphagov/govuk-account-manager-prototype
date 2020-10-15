# frozen_string_literal: true

require "geocoder"

module SecurityHelper
  def ip_to_country(ip)
    Geocoder.search(ip)&.first&.country
  end
end
