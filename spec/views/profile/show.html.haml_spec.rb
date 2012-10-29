require 'spec_helper'

describe "profile/show" do
  before(:each) do
    @user = assign(:user, stub_model(User,
      :username => "pie",
      :password => "steak&kidney",
      :email => "steak-and-kidney@pie.com",
      :created_at => Time.new
    ))
  end

  it "shows account creation date" do
    render
    rendered.should contain "A Growstuff user since"
  end

end
