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

  it 'should show the location' do
    rendered.should have_content @garden.location
  end

  it 'should show the area' do
    rendered.should have_content pluralize(@garden.area, @garden.area_unit)
  end

  it 'should show the description' do
    rendered.should have_content "totally cool garden"
  end

  it 'renders markdown in the description' do
    assert_select "strong", "totally"
  end

  it 'should show plantings on the garden page' do
    rendered.should have_content @planting.crop.name
  end

  it "doesn't show the note about random plantings" do
    rendered.should_not have_content "Note: these are a random selection"
  end

  context 'signed in' do
    before :each do
      sign_in @owner
      render
    end

    it 'should have an edit button' do
      rendered.should have_link 'edit_garden_link'
    end

    it "shows a 'plant something' button" do
      rendered.should have_content "Plant something"
    end

    it "shows an 'add photo' button" do
      rendered.should have_content "Add photo"
    end

    it "links to the right crop in the planting link" do
      assert_select("a[href='#{new_planting_path}?garden_id=#{@garden.id}']")
    end
  end
end
