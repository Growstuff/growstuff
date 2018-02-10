require 'rails_helper'

describe 'home/_crops.html.haml', type: "view" do
  let!(:crop) { FactoryBot.create(:crop, plantings: FactoryBot.create_list(:planting, 3)) }
  let!(:photo) { FactoryBot.create(:photo, plantings: [crop.plantings.first]) }
  let(:planting) { crop.plantings.first }

  before(:each) { render }
  it 'shows crops section' do
    assert_select 'h2', text: 'Some of our crops'
    assert_select "a[href='#{crop_path(crop)}']"
  end

  it 'shows plantings section' do
    assert_select 'h2', text: 'Recently planted'
    rendered.should have_content planting.location
  end

  it 'shows recently added crops' do
    assert_select 'h2', text: 'Recently planted'
  end

  it 'includes a link to all crops' do
    assert_select "a[href='#{crops_path}']", text: /View all crops/
  end
end
