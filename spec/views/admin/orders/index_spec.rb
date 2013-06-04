require 'spec_helper'

describe 'admin/orders/index.html.haml', :type => "view" do
  before(:each) do
    @member = FactoryGirl.create(:admin_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    render
  end

  it "includes a search form for orders" do
    assert_select "form"
    assert_select "input#search_text"
    assert_select "select#search_by"
  end
end
