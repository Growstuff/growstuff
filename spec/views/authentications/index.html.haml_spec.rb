require 'spec_helper'

describe "authentications/index" do
  before(:each) do
    assign(:authentications, [
      stub_model(Authentication,
        :member_id => 1,
        :provider => "Provider",
        :uid => "Uid",
        :secret => "Secret"
      ),
      stub_model(Authentication,
        :member_id => 1,
        :provider => "Provider",
        :uid => "Uid",
        :secret => "Secret"
      )
    ])
  end

  it "renders a list of authentications" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Provider".to_s, :count => 2
    assert_select "tr>td", :text => "Uid".to_s, :count => 2
    assert_select "tr>td", :text => "Secret".to_s, :count => 2
  end
end
