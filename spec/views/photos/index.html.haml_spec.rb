require 'spec_helper'

describe "photos/index" do
  before(:each) do
    assign(:photos, [
      stub_model(Photo,
        :owner_id => 1,
        :flickr_photo_id => 2,
        :thumbnail_url => "Thumbnail Url",
        :fullsize_url => "Fullsize Url"
      ),
      stub_model(Photo,
        :owner_id => 1,
        :flickr_photo_id => 2,
        :thumbnail_url => "Thumbnail Url",
        :fullsize_url => "Fullsize Url"
      )
    ])
  end

  it "renders a list of photos" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Thumbnail Url".to_s, :count => 2
    assert_select "tr>td", :text => "Fullsize Url".to_s, :count => 2
  end
end
