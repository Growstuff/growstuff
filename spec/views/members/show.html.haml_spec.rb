require 'spec_helper'

describe "members/show" do
  before(:each) do
    @time = Time.new
    @member = assign(:user, stub_model(User,
      :username => "pie",
      :password => "steak&kidney",
      :email => "steak-and-kidney@pie.com",
      :created_at => @time,
      :tos_agreement => true
    ))
  end

  it "shows account creation date" do
    render
    rendered.should contain "Member since"
    rendered.should contain @time.strftime("%B %d, %Y")
  end

end
