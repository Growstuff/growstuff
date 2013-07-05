require 'spec_helper'

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
    assign(:flickr_auth, FactoryGirl.create(:flickr_authentication, :member => @member))
  end

  it "shows a list of photos" do
    render
    assert_select "ul.thumbnails"
  end
end
