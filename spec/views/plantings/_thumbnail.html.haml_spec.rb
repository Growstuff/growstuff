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

describe "plantings/_thumbnail" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @crop = FactoryGirl.create(:tomato)

    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )
  end

  context "simple view" do
    before(:each) do
      render :partial => "thumbnail", :locals => {
        :planting => @planting,
      }
    end

    it "renders the quantity planted" do
      rendered.should have_content "33"
    end

    it "renders the date planted" do
      rendered.should have_content @planting.planted_at.to_s(:default)
    end

    it "shows the name of the crop" do
      rendered.should have_content @crop.name
    end

    it "shows the description by default" do
      rendered.should have_content "This is a"
    end
  end

  context "with complicated args" do
    before(:each) do
      render :partial => "thumbnail", :locals => {
        :planting => @planting,
        :hide_description => true
      }
    end

    it "hides the description if asked" do
      rendered.should_not have_content "This is a"
    end
  end

end
