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

describe "photos/index" do
  before(:each) do
    page = 1
    per_page = 2
    total_entries = 2
    photos = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:photo),
        FactoryGirl.create(:photo)
      ])
    end
    assign(:photos, photos)
  end

  it "renders a gallery of photos" do
    render
    assert_select ".thumbnail", count: 2
    assert_select "img", count: 2
  end
end
