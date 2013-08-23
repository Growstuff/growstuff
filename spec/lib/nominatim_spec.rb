require 'nominatim'

describe 'Nominatim' do

  it 'returns stubbed locations in test env' do
    Nominatim.add_stub(
      "Thornbury", {
        'latitude' => 1337,
        'longitude' => 42,
      }
    )
    Nominatim.geocode("Thornbury").should == {
      'latitude' => 1337,
      'longitude' => 42,
    }
  end

  # Uncomment this and run in dev environment to see live data
  # It will fail because Thornbury is not 1337 :)
  # it 'finds a real location' do
  #   Nominatim.geocode("Thornbury").should == {
  #    'latitude' => 1337,
  #    'longitude' => 42,
  #  }
  # end
end
