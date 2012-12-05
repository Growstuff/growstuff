require 'spec_helper'

describe "updates/index" do
  before(:each) do
    user = User.create!(
      :username => "test_user",
      :email => "test@growstuff.org",
<<<<<<< HEAD
      :password => "password"
=======
      :password => "password",
      :tos_agreement => true
>>>>>>> 77233cbb73b4d97b6ff9981de3e948842f8dbb27
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
end
