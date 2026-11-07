# frozen_string_literal: true

# For a spec with a `planting`: gives its crop heat figures and its garden a location and weather, so the
# planting is predicted to be ready on the fifth day after it was planted, whatever the crop's median days
# say. Each of those days gives 7 degree days above the crop's base of 10°C, and a first harvest needs 30.
RSpec.shared_context 'with a heat predicted first harvest' do
  let(:heat_predicted_on) { planting.planted_at.to_date + 4 }

  before do
    planting.garden.update_columns(latitude: -41.29, longitude: 174.78) # rubocop:disable Rails/SkipsModelValidations
    planting.crop.scientific_names.create!(name: 'Solanum lycopersicum', creator: create(:member))
    create(:ecocrop_data, scientificname: 'Solanum lycopersicum', tmin: 10, topmn: 20, topmx: 30, gmin: 2, gmax: 60)
    (planting.planted_at.to_date..heat_predicted_on).each do |date|
      create(:weather_reading, date:, temp_max_c: 22.0, temp_min_c: 12.0)
    end
  end
end
