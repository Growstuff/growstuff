require 'spec_helper'

describe "members/show" do
  before(:each) do
    @member = User.create!(
      :username => "pie",
      :password => "steak&kidney",
      :email => "steak-and-kidney@pie.com",
    )
    @time = @member.created_at
    @member.gardens.create(:name => 'My Garden', :user_id => @member.id)
  end

  it "shows account creation date" do
    render
    rendered.should contain "Member since"
    rendered.should contain @time.strftime("%B %d, %Y")
  end

end
