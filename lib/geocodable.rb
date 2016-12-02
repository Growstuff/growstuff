module Geocodable
  def self.included(base)
    base.extend(self)
  end

  private

  def geocode
    unless self.location.blank?
      self.latitude, self.longitude =
        Geocoder.coordinates(location, params: { limit: 1 })
    end
  end

  def empty_unwanted_geocodes
    if self.location.blank?
      self.latitude = nil
      self.longitude = nil
    end
  end
end
