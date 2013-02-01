require 'spec_helper'

describe "crops/index" do
  before(:each) do
    controller.stub(:current_user) { Member.new }
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

  context "logged in" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      render
    end

    it "shows a new crop link" do
      rendered.should contain "New Crop"
    end
  end
end
