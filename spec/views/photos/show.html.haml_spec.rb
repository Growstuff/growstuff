require 'rails_helper'

describe "photos/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
  end

  context "CC-licensed photo" do
    before(:each) do
      @photo = assign(:photo, FactoryGirl.create(:photo, :owner => @member))
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

    it "shows a link to the original image" do
      assert_select "a", :href => @photo.link_url, :text => "View on Flickr"
    end

    it "has a delete button" do
      assert_select "a[href=#{photo_path(@photo)}]", 'Delete Photo'
    end
  end

  context "unlicensed photo" do
    before(:each) do
      @photo = assign(:photo, FactoryGirl.create(:unlicensed_photo))
      render
    end

    it "contains the phrase 'All rights reserved'" do
      rendered.should have_content "All rights reserved"
    end

  end

end
