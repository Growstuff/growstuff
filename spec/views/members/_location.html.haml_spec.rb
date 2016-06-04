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

describe "members/_location" do
  context "member with location" do
    before(:each) do
      @member = FactoryGirl.create(:london_member)
      render partial: 'members/location', locals: { member: @member }
    end

    it 'shows location if available' do
      rendered.should have_content @member.location
    end

    it "links to the places page" do
      assert_select "a", href: place_path(@member.location)
    end
  end

  context "member with no location" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      render partial: 'members/location', locals: { member: @member }
    end

    it 'shows unknown location' do
      rendered.should have_content "unknown location"
    end

    it "doesn't link anywhere" do
      assert_select "a", false
    end

  end

end
