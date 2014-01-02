require 'spec_helper'

describe "crops/edit" do
  before(:each) do
    controller.stub(:current_user) {
      FactoryGirl.create(:crop_wrangling_member)
    }
    @crop = assign(:crop, FactoryGirl.create(:maize))
    render
  end

  it "shows the creator" do
    rendered.should contain "Added by #{@crop.creator} less than a minute ago."
  end

  it "renders the edit crop form" do
    assert_select "form", :action => crops_path(@crop), :method => "post" do
      assert_select "input#crop_name", :name => "crop[name]"
      assert_select "input#crop_en_wikipedia_url", :name => "crop[en_wikipedia_url]"
    end
  end
end
