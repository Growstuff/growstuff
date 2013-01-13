require 'spec_helper'

describe "members/show" do

  before(:each) do
    @member = FactoryGirl.create(:member)
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

  it "shows the auto-created garden" do
    assert_select "li.active>a", :text => "Garden"
  end

  context "signed in member" do
    before(:each) do
      sign_in @member
      render
    end

    it "contains a 'New Garden' link" do
      assert_select "a[href=#garden_new]", :text => "New Garden"
    end
  end

end
