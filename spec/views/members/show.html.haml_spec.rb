require 'spec_helper'

describe "members/show" do

  before(:each) do
    @member = FactoryGirl.create(:user)
    @time = @member.created_at

    # need @garden to render the page
    @garden = Garden.new
    render
  end

  it "shows account creation date" do
    rendered.should contain "Member since"
    rendered.should contain @time.strftime("%B %d, %Y")
  end

  it "contains a gravatar icon" do
    assert_select "img", :src => /gravatar\.com\/avatar/
  end

  context "no gardens" do
    it "shouldn't mention the name of a garden" do
      rendered.should_not contain "My Garden"
    end
  end

  context "signed in user" do
    before(:each) do
      sign_in @member
      render
    end

    it "contains a 'New Garden' link" do
      assert_select "a[href=#garden_new]", :text => "New Garden"
    end
  end

  context "user has a garden" do
    before(:each) do
      @member.gardens.create(:name => 'My Garden', :user_id => @member.id)
      render
    end

    it "displays a garden, if the user has one" do
      rendered.should contain "My Garden"
    end
  end

end
