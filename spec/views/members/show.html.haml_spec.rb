require 'spec_helper'

describe "members/show" do
  before(:each) do
    @member = User.create!(
      :username => "pie",
      :password => "steak&kidney",
      :email => "steak-and-kidney@pie.com",
      :tos_agreement => true
    )
    @time = @member.created_at
    @member.gardens.create(:name => 'My Garden', :user_id => @member.id)
    render
  end

  it "shows account creation date" do
    rendered.should contain "Member since"
    rendered.should contain @time.strftime("%B %d, %Y")
  end

  it "contains a gravatar icon" do
    assert_select "img", :src => /gravatar\.com\/avatar/
  end

end
