module Geocodable
  def self.included(base)
    base.extend(self)
  end

  private

  def empty_unwanted_geocodes
    return unless location.blank?
    self.latitude = nil
    self.longitude = nil
  end
end
