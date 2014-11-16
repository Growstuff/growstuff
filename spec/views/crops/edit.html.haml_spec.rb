require 'rails_helper'

describe "crops/edit" do
  before(:each) do
    controller.stub(:current_user) {
      FactoryGirl.create(:crop_wrangling_member)
    }
    @crop = FactoryGirl.create(:maize)
    3.times do
      @crop.scientific_names.build
    end
    assign(:crop, @crop)
    render
  end

  it "shows the creator" do
    rendered.should have_content "Added by #{@crop.creator} less than a minute ago."
  end

  it "renders the edit crop form" do
    assert_select "form", :action => crops_path(@crop), :method => "post" do
      assert_select "input#crop_name", :name => "crop[name]"
      assert_select "input#crop_en_wikipedia_url", :name => "crop[en_wikipedia_url]"
    end
  end

  it "shows three fields for scientific_name" do
    assert_select "input#crop_scientific_names_attributes_0_scientific_name", :count => 1
    assert_select "input#crop_scientific_names_attributes_1_scientific_name", :count => 1
    assert_select "input#crop_scientific_names_attributes_2_scientific_name", :count => 1
  end
end
