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

describe "crops/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    @tomato = FactoryGirl.create(:tomato)
    @maize  = FactoryGirl.create(:maize)
    assign(:crops, [@tomato, @maize])
    paginated_crops = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([ @tomato, @maize ])
    end
    assign(:paginated_crops, paginated_crops)
  end

  it "shows photos where available" do
    @planting = FactoryGirl.create(:planting, crop: @tomato)
    @photo = FactoryGirl.create(:photo)
    @planting.photos << @photo
    render
    assert_select "img", src: @photo.thumbnail_url
  end

  it "linkifies crop images" do
   render
   assert_select "img", src: :tomato
  end

  context "logged in and crop wrangler" do
    before(:each) do
      @member = FactoryGirl.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "shows a new crop link" do
      rendered.should have_content "New Crop"
    end
  end

  context "downloads" do
    it "offers data downloads" do
      render
      rendered.should have_content "The data on this page is available in the following formats:"
      assert_select "a", href: crops_path(format: 'csv')
      assert_select "a", href: crops_path(format: 'json')
      assert_select "a", href: crops_path(format: 'rss')
    end
  end
end
