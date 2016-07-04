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

describe "photos/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
  end

  context "CC-licensed photo" do
    before(:each) do
      @photo = assign(:photo, FactoryGirl.create(:photo, owner: @member))
      render
    end

    it "shows the image" do
      assert_select "img[src='#{@photo.fullsize_url}']"
    end

    it "links to the owner's profile" do
      assert_select "a", href: @photo.owner
    end

    it "links to the CC license" do
      assert_select "a", href: @photo.license_url,
        text: @photo.license_name
    end

    it "shows a link to the original image" do
      assert_select "a", href: @photo.link_url, text: "View on Flickr"
    end

    it "has a delete button" do
      assert_select "a[href='#{photo_path(@photo)}']", 'Delete Photo'
    end
  end

  context "unlicensed photo" do
    before(:each) do
      @photo = assign(:photo, FactoryGirl.create(:unlicensed_photo))
      render
    end

    it "contains the phrase 'All rights reserved'" do
      rendered.should have_content "All rights reserved"
    end

  end

end
