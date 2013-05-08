require 'spec_helper'

describe "photos/show" do
  before(:each) do
    @photo = assign(:photo, stub_model(Photo,
      :owner_id => 1,
      :flickr_photo_id => 2,
      :thumbnail_url => "Thumbnail Url",
      :fullsize_url => "Fullsize Url"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/Thumbnail Url/)
    rendered.should match(/Fullsize Url/)
  end
end
