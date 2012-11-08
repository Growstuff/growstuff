require 'spec_helper'

describe "updates/show" do
  before(:each) do
    user = User.create! :username => "test_user", :email => "test@example.com",
      :password => "password"
    @update = assign(:update, stub_model(Update,
      :user_id => user.id,
      :subject => "Subject",
      :body => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    rendered.should match(/test_user/)
    # Subject goes in title
    rendered.should match(/MyText/)
  end
end
