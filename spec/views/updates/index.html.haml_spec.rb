require 'spec_helper'

describe "updates/index" do
  before(:each) do
    user = User.create!(
      :username => "test_user",
      :email => "test@growstuff.org",
      :password => "password",
      :tos_agreement => true
    )
    assign(:updates, [
      stub_model(Update,
        :user_id => user.id,
        :subject => "Subject",
        :body => "MyText"
      ),
      stub_model(Update,
        :user_id => user.id,
        :subject => "Subject",
        :body => "MyText"
      )
    ])
  end

  it "renders a list of updates" do
    render
    assert_select "div.update", :count => 2
    assert_select "div.update>h3", :text => "Subject".to_s, :count => 2
    assert_select "div.update>div.update-body",
      :text => "MyText".to_s, :count => 2
  end
    
  it "counts the number of updates" do 
    render
    rendered.should contain "Displaying 2 updates"
  end
   
end
