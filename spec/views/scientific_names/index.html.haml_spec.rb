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

describe "scientific_names/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:scientific_names, [
      FactoryGirl.create(:zea_mays),
      FactoryGirl.create(:solanum_lycopersicum)
    ])
  end

  it "renders a list of scientific_names" do
    render
    assert_select "tr>td", text: "Zea mays".to_s
    assert_select "tr>td", text: "Solanum lycopersicum".to_s
  end

  it "doesn't show edit/destroy links" do
    render
    rendered.should_not have_content "Edit"
    rendered.should_not have_content "Delete"
  end

  context "logged in and crop wrangler" do
    before(:each) do
      @member = FactoryGirl.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
    end

    it "shows edit/destroy links" do
      render
      rendered.should have_content "Edit"
      rendered.should have_content "Delete"
    end
  end
end
