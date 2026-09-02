require 'rails_helper'

RSpec.feature 'Set location', type: :feature do
  let(:member) { FactoryBot.create(:member) }

  before do
    login_as(member, scope: :member)
  end

  scenario 'member sets their location by clicking on the map', js: true do
    visit set_location_member_path(member)

    # Test clicking on the map
    page.execute_script("map.fire('click', { latlng: L.latLng(40.7128, -74.0060) })")
    expect(find('#member_latitude').value).to eq('40.7128')
    expect(find('#member_longitude').value).to eq('-74.006')

    # Mock geocoding
    geocoder_result = instance_double('Geocoder::Result::Nominatim',
                                      city: 'New York',
                                      town: nil,
                                      village: nil,
                                      hamlet: nil)
    allow(Geocoder).to receive(:search).with([40.71, -74.01]).and_return([geocoder_result])

    click_button 'Update location'

    expect(page).to have_content('Location updated.')
    member.reload
    expect(member.location).to eq('New York')
    expect(member.latitude).to eq(40.71)
    expect(member.longitude).to eq(-74.01)
  end

  scenario 'member uses "Find my location"', js: true do
    visit set_location_member_path(member)

    # Mock browser's geolocation
    page.execute_script("
      navigator.geolocation.getCurrentPosition = function(success) {
        var position = { coords: { latitude: 34.0522, longitude: -118.2437 } };
        success(position);
      }
    ")

    click_button 'Find my location'

    expect(find('#member_latitude').value).to eq('34.0522')
    expect(find('#member_longitude').value).to eq('-118.2437')

    # Mock geocoding
    geocoder_result = instance_double('Geocoder::Result::Nominatim',
                                      city: 'Los Angeles',
                                      town: nil,
                                      village: nil,
                                      hamlet: nil)
    allow(Geocoder).to receive(:search).with([34.05, -118.24]).and_return([geocoder_result])

    click_button 'Update location'

    expect(page).to have_content('Location updated.')
    member.reload
    expect(member.location).to eq('Los Angeles')
    expect(member.latitude).to eq(34.05)
    expect(member.longitude).to eq(-118.24)
  end

  scenario 'geocoding fails', js: true do
    visit set_location_member_path(member)

    page.execute_script("map.fire('click', { latlng: L.latLng(1.2345, 6.7890) })")

    allow(Geocoder).to receive(:search).with([1.23, 6.79]).and_return([])

    click_button 'Update location'

    expect(page).to have_content('Location updated.')
    member.reload
    expect(member.location).to eq('Location near 1.23, 6.79')
    expect(member.latitude).to eq(1.23)
    expect(member.longitude).to eq(6.79)
  end
end
