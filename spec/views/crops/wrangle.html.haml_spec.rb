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

describe "crops/wrangle" do
  before(:each) do
    @member = FactoryGirl.create(:crop_wrangling_member)
    controller.stub(:current_user) { @member }
    page = 1
    per_page = 2
    total_entries = 2
    @tomato = FactoryGirl.create(:tomato)
    @maize  = FactoryGirl.create(:maize)
    crops = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([ @tomato, @maize ])
    end
    assign(:crops, crops)
    assign(:crop_wranglers, Role.crop_wranglers)
  end

  it 'contains handy links for wranglers' do
    render
    rendered.should have_content "Crop wrangler guidelines"
    rendered.should have_content "mailing list"
  end

  it 'has a link to add a crop' do
    render
    assert_select "a", href: new_crop_path
  end

  it "renders a list of crops" do
    render
    assert_select "a", text: @maize.name
    assert_select "a", text: @tomato.name
  end

end
