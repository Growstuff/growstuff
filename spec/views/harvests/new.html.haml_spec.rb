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

describe "harvests/new" do
  before(:each) do
    assign(:harvest, FactoryGirl.create(:harvest))
    render
  end

  it "renders new harvest form" do
    assert_select "form", action: harvests_path, method: "post" do
      assert_select "input#crop", class: "ui-autocomplete-input"
      assert_select "input#harvest_crop_id", name: "harvest[crop_id]"
      assert_select "select#harvest_plant_part_id", name: "harvest[plant_part_id]"
# some browsers interpret <input type="number"> without a step as "integer"
      assert_select "input#harvest_quantity[step=any]", name: "harvest[quantity]"
      assert_select "input#harvest_weight_quantity[step=any]", name: "harvest[quantity]"
      assert_select "select#harvest_unit", name: "harvest[unit]"
      assert_select "select#harvest_weight_unit", name: "harvest[unit]"
      assert_select "textarea#harvest_description", name: "harvest[description]"
    end
  end
end
