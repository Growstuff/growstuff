module Geocodable
  def self.included(base)
    base.extend(self)
  end

  private

  def empty_unwanted_geocodes
    return if location.present?
    self.latitude = nil
    self.longitude = nil
  end
end
