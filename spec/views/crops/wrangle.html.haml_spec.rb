require 'spec_helper'

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
  end

  it 'contains handy links for wranglers' do
    render
    rendered.should contain "Crop wrangler guidelines"
    rendered.should contain "mailing list"
  end

  it 'has a link to add a crop' do
    render
    assert_select "a", :href => new_crop_path
  end

  it "renders a list of crops" do
    render
    assert_select "a", :text => @maize.name
    assert_select "a", :text => @tomato.name
  end

end
