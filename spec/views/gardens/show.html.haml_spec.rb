## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "gardens/show" do
  before(:each) do
    @owner    = FactoryGirl.create(:member)
    controller.stub(:current_user) { @owner }
    @garden   = FactoryGirl.create(:garden, owner: @owner)
    @planting = FactoryGirl.create(:planting, garden: @garden)
    assign(:garden, @garden)
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
      rendered.should have_content 'Edit'
    end

    it "shows a 'plant something' button" do
      rendered.should have_content "Plant something"
    end

    it "links to the right crop in the planting link" do
      assert_select("a[href='#{new_planting_path}?garden_id=#{@garden.id}']")
    end
  end

end
