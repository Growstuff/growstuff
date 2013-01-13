require 'spec_helper'

describe "members/index" do
  before(:each) do
    assign(:members, [
      FactoryGirl.create(:user),
      FactoryGirl.create(:long_name_user)
    ])
    render
  end

  it "truncates long names" do
    rendered.should contain "marmaduke blundell-hollinsh..."
  end

  it "does not truncate short names" do
    rendered.should contain "user1"
    rendered.should_not contain "user1..."
  end

  it "counts the number of members" do
    rendered.should contain "Displaying 2 members"
  end

  it "contains two gravatar icons" do
    assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
  end

end
