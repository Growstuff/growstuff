# frozen_string_literal: true

# Members who live somewhere. Saving a member geocodes their location, and the
# test geocoder only knows places it has been told about, so tell it first.
module LocatedMembers
  def create_located_member(location, latitude, longitude, **attributes)
    Geocoder::Lookup::Test.add_stub(location, [{ 'coordinates' => [latitude, longitude] }])
    create(:member, location:, **attributes)
  end
end

RSpec.configure { |config| config.include LocatedMembers }
