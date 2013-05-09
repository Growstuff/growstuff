require 'spec_helper'

describe "photos/show" do
  before(:each) do
    @photo = assign(:photo, FactoryGirl.create(:photo))
  end

  it "shows the image" do
    render
    assert_select "img[src=#{@photo.fullsize_url}]"
  end
end
