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

describe "crops/edit" do
  before(:each) do
    controller.stub(:current_user) {
      FactoryGirl.create(:crop_wrangling_member)
    }
    @crop = FactoryGirl.create(:maize)
    3.times do
      @crop.scientific_names.build
    end
    assign(:crop, @crop)
    render
  end

  it "shows the creator" do
    rendered.should have_content "Added by #{@crop.creator} less than a minute ago."
  end

end
