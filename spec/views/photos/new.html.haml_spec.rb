require 'spec_helper'

describe "photos/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
    assign(:photos, [])
    assign(:flickr_auth, FactoryGirl.create(:flickr_authentication, :member => @member))
  end

  it "shows a list of photos" do
    render
    assert_select "ul.thumbnails"
  end
end
