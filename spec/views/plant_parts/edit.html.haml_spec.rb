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

describe "plant_parts/edit" do
  before(:each) do
    @plant_part = assign(:plant_part, stub_model(PlantPart,
      name: "MyString"
    ))
  end

  it "renders the edit plant_part form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: plant_parts_path(@plant_part), method: "post" do
      assert_select "input#plant_part_name", name: "plant_part[name]"
    end
  end
end
