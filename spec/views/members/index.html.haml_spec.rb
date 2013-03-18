require 'spec_helper'

describe "members/index" do
  before(:each) do
    assign(:members, [
      FactoryGirl.create(:member),
      FactoryGirl.create(:member)
    ])
    render
  end

  it "counts the number of members" do
    rendered.should contain "Displaying 2 members"
  end

  it "contains two gravatar icons" do
    assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
  end

end
