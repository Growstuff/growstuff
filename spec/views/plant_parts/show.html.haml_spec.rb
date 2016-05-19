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

describe "plant_parts/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @pp = FactoryGirl.create(:plant_part)
    @harvest = FactoryGirl.create(:harvest, plant_part: @pp)
    assign(:plant_part, @pp)
  end

  it "renders a list of crops harvested for this part" do
    render
    @pp.crops.each do |c|
      rendered.should have_content c.name
      assert_select "a", href: crop_path(c)
    end
  end
end

