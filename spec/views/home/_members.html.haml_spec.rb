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

describe 'home/_members.html.haml', type: "view" do
  before(:each) do
    @member = FactoryGirl.create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:members, [@member])

    @planting = FactoryGirl.create(:planting, owner: @member)
    render
  end

  it 'Has a heading' do
    rendered.should have_content "Some of our members"
  end

  it 'Shows members' do
    rendered.should have_content @member.login_name
    rendered.should have_content @member.location
    rendered.should have_content @planting.crop_name
  end

end
