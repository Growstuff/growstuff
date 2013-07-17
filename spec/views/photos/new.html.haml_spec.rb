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
    assign(:sets, {"foo" => "bar"})
    assign(:flickr_auth, FactoryGirl.create(:flickr_authentication, :member => @member))
    render
  end

  it "shows a dropdown with sets from Flickr" do
    assert_select "select#set"
  end

  it "shows a list of photos" do
    assert_select "ul.thumbnails"
  end
end
