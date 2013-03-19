require 'spec_helper'

describe "crops/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:crops, [
      FactoryGirl.create(:tomato),
      FactoryGirl.create(:maize)
    ])
  end

  it "renders a list of crops" do
    render
    assert_select "a", :text => "Maize"
    assert_select "a", :text => "Tomato"
  end

  it "counts the number of crops" do
    render
    rendered.should contain "Displaying 2 crops"
  end

  context "logged in and crop wrangler" do
    before(:each) do
      @member = FactoryGirl.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "shows a new crop link" do
      rendered.should contain "New Crop"
    end
  end
end
