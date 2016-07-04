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

describe "photos/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
    page = 1
    per_page = 2
    total_entries = 2
    photos = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([])
    end
    assign(:photos, photos)
    assign(:flickr_auth, FactoryGirl.create(:flickr_authentication, member: @member))
  end

  context "user has no photosets" do
    it "doesn't show a dropdown with sets from Flickr" do
      render
      assert_select "select#set", false
    end
  end

  context "user has photosets" do
    before(:each) do
      assign(:sets, {"foo" => "bar"}) # Hash of names => IDs
    end

    it "shows a dropdown with sets from Flickr" do
      render
      assert_select "select#set"
    end

    it "shows the current photoset" do
      assign(:current_set, "bar")   # the ID of the set
      render
      assert_select "h2", "foo" # the name of the set
    end
  end

end
