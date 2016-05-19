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

describe "scientific_names/edit" do
  context "logged in" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @scientific_name = assign(:scientific_name,
        FactoryGirl.create(:zea_mays)
      )
      render
    end

  it "shows the creator" do
    rendered.should have_content "Added by #{@scientific_name.creator} less than a minute ago."
  end

    it "renders the edit scientific_name form" do
      assert_select "form", action: scientific_names_path(@scientific_name), method: "post" do
        assert_select "input#scientific_name_scientific_name", name: "scientific_name[scientific_name]"
        assert_select "select#scientific_name_crop_id", name: "scientific_name[crop_id]"
      end
    end
  end

end
