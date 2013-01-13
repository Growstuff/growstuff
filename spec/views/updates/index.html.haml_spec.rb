require 'spec_helper'

describe "updates/index" do
  before(:each) do
    @member = FactoryGirl.create(:user)
    @update1 = FactoryGirl.build(:update, :user => @member)
    @update2 = FactoryGirl.build(:update, :user => @member)
    assign(:updates, [@update1, @update2])
    render
  end

  it "renders a list of updates" do
    assert_select "div.update", :count => 2
    assert_select "h3", :text => "An Update".to_s, :count => 2
    assert_select "div.update-body",
      :text => "This is some text.".to_s, :count => 2
  end

  it "counts the number of updates" do
    rendered.should contain "Displaying 2 updates"
  end

  it "contains two gravatar icons" do
    assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
  end
end
