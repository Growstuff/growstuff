require 'rails_helper'

describe "authentications/index" do
  before(:each) do
    assign(:authentications, [
      stub_model(Authentication,
        :member_id => 1,
        :provider => "Provider",
        :uid => "Uid",
        :name => "Name"
      ),
      stub_model(Authentication,
        :member_id => 1,
        :provider => "Provider",
        :uid => "Uid",
        :name => "Name"
      )
    ])
  end

  it "renders a list of authentications" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select ".authentication", :count => 2
    assert_select ".provider", :text => "Provider".to_s, :count => 2
    assert_select ".name", :text => "Name".to_s, :count => 2
  end
end
