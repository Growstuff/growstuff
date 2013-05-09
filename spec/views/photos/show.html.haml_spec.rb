require 'spec_helper'

describe "photos/show" do
  context "CC-licensed photo" do
    before(:each) do
      @photo = assign(:photo, FactoryGirl.create(:photo))
      render
    end

    it "shows the image" do
      assert_select "img[src=#{@photo.fullsize_url}]"
    end

    it "links to the owner's profile" do
      assert_select "a", :href => @photo.owner
    end

    it "links to the CC license" do
      assert_select "a", :href => @photo.license_url,
        :text => @photo.license_name
    end

    it "shows the title as a link to the original image" do
      assert_select "a", :href => @photo.link_url, :text => @photo.title
    end
  end

  context "unlicensed photo" do
    before(:each) do
      @photo = assign(:photo, FactoryGirl.create(:unlicensed_photo))
      render
    end

    it "contains the phrase 'All rights reserved'" do
      rendered.should contain "All rights reserved"
    end
end

end
