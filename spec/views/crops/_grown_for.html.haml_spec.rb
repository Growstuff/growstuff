require 'rails_helper'

describe "crops/_grown_for" do
  let(:crop) { FactoryBot.create(:crop) }
  let(:plant_path) { FactoryBot.create(:plant_part) }
  let!(:harvest) do
    FactoryBot.create(:harvest,
      crop: crop,
      plant_part: plant_path)
  end

  it 'shows plant parts' do
    render partial: 'crops/grown_for', locals: { crop: crop }
    rendered.should have_content plant_path.name
    assert_select "a", href: plant_part_path(plant_path)
  end
end
