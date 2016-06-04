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

describe "places/show" do
  before(:each) do
    @member = FactoryGirl.create(:london_member)
    @nearby_members = [FactoryGirl.create(:member)]
    controller.stub(:current_user) { @member }
    controller.stub(:current_member) { @member }
    @place = @member.location
    render
  end

  it "shows the selected place" do
    view.content_for(:title).should match @place
  end

  it "shows the selected place in the textbox" do
    assert_select "#new_place", value: @place
  end

  it "shows the names of nearby members" do
    @nearby_members.each do |m|
      rendered.should have_content m.login_name
    end
  end

end
