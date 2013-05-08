require 'spec_helper'

describe "photos/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
    assign(:photo, FactoryGirl.create(:photo))
    assign(:flickr_auth, FactoryGirl.create(:flickr_authentication, :member => @member))
  end

  it "renders new photo form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => photos_path, :method => "post" do
      assert_select "input#photo_owner_id", :name => "photo[owner_id]"
      assert_select "input#photo_flickr_photo_id", :name => "photo[flickr_photo_id]"
      assert_select "input#photo_thumbnail_url", :name => "photo[thumbnail_url]"
      assert_select "input#photo_fullsize_url", :name => "photo[fullsize_url]"
    end
  end
end
