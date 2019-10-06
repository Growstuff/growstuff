require 'rails_helper'

describe 'gardens/show' do
  before do
    @owner = FactoryBot.create(:member)
    controller.stub(:current_user) { @owner }
    @garden = FactoryBot.create(:garden, owner: @owner)
    @planting = FactoryBot.create(:planting, garden: @garden, owner: @garden.owner)
    assign(:garden, @garden)
    assign(:current_plantings, [@planting])
    assign(:finished_plantings, [])
    render
  end

  it 'shows the location' do
    expect(rendered).to have_content @garden.location
  end

  it 'shows the area' do
    expect(rendered).to have_content pluralize(@garden.area, @garden.area_unit)
  end

  it 'shows the description' do
    expect(rendered).to have_content 'totally cool garden'
  end

  it 'renders markdown in the description' do
    assert_select 'strong', 'totally'
  end

  it 'shows plantings on the garden page' do
    expect(rendered).to have_content @planting.crop.name
  end
end
