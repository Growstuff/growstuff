require 'spec_helper'

describe "photos/edit" do
  before(:each) do
    @photo = assign(:photo, stub_model(Photo,
      :owner_id => 1,
      :flickr_photo_id => 1,
      :thumbnail_url => "MyString",
      :fullsize_url => "MyString"
    ))
  end

  it "renders the edit photo form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => photos_path(@photo), :method => "post" do
      assert_select "input#photo_owner_id", :name => "photo[owner_id]"
      assert_select "input#photo_flickr_photo_id", :name => "photo[flickr_photo_id]"
      assert_select "input#photo_thumbnail_url", :name => "photo[thumbnail_url]"
      assert_select "input#photo_fullsize_url", :name => "photo[fullsize_url]"
    end
  end
end
