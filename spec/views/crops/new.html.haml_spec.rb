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

describe "crops/new" do
  before(:each) do
    @crop = FactoryGirl.create(:maize)
    3.times do
      @crop.scientific_names.build
    end
    assign(:crop, @crop)
    @member = FactoryGirl.create(:crop_wrangling_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    render
  end

  it "shows a link to crop wrangling guidelines" do
    assert_select "a[href^='http://wiki.growstuff.org']", "crop wrangling guide"
  end

end
