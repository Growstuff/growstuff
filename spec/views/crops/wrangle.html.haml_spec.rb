require 'rails_helper'

describe "crops/wrangle" do
  before(:each) do
    @member = FactoryBot.create(:crop_wrangling_member)
    controller.stub(:current_user) { @member }
    page = 1
    per_page = 2
    total_entries = 2
    @tomato = FactoryBot.create(:tomato)
    @maize  = FactoryBot.create(:maize)
    crops = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([@tomato, @maize])
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
