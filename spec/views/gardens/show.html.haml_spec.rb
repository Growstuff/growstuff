require 'rails_helper'

describe "gardens/show" do
  before(:each) do
    @owner = FactoryBot.create(:member)
    controller.stub(:current_user) { @owner }
    @garden   = FactoryBot.create(:garden, owner: @owner)
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
    expect(rendered).to have_content "totally cool garden"
  end

  it 'renders markdown in the description' do
    assert_select "strong", "totally"
  end

  it 'shows plantings on the garden page' do
    expect(rendered).to have_content @planting.crop.name
  end

  it "doesn't show the note about random plantings" do
    expect(rendered).to have_content "Note: these are a random selection"
  end

  context 'signed in' do
    before :each do
      sign_in @owner
      render
    end

    it "links to the right crop in the planting link" do
      assert_select("a[href='#{new_planting_path}?garden_id=#{@garden.id}']")
    end
  end
end
