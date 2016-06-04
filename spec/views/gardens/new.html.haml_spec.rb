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

describe "gardens/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @garden = FactoryGirl.create(:garden, owner: @member)
    assign(:garden, @garden)
    render
  end

  it "renders new garden form" do
    assert_select "form", action: gardens_path, method: "post" do
      assert_select "input#garden_name", name: "garden[name]"
      assert_select "textarea#garden_description", name: "garden[description]"
      assert_select "input#garden_location", name: "garden[location]"
      assert_select "input#garden_area", name: "garden[area]"
      assert_select "select#garden_area_unit", name: "garden[area_unit]"
      assert_select "input#garden_active", name: "garden[active]"
    end
  end
end
