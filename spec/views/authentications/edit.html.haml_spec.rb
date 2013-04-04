require 'spec_helper'

describe "authentications/edit" do
  before(:each) do
    @authentication = assign(:authentication, stub_model(Authentication,
      :member_id => 1,
      :provider => "MyString",
      :uid => "MyString",
      :secret => "MyString"
    ))
  end

  it "renders the edit authentication form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => authentications_path(@authentication), :method => "post" do
      assert_select "input#authentication_member_id", :name => "authentication[member_id]"
      assert_select "input#authentication_provider", :name => "authentication[provider]"
      assert_select "input#authentication_uid", :name => "authentication[uid]"
      assert_select "input#authentication_secret", :name => "authentication[secret]"
    end
  end
end
