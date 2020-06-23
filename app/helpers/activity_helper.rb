# frozen_string_literal: true

require "geocoder"

module ActivityHelper
  def ip_to_country(ip)
    Geocoder.search(ip).first.country
  end
end
