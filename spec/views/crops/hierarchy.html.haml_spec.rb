require 'spec_helper'

describe "crops/hierarchy" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @tomato = FactoryGirl.create(:tomato)
    @roma = FactoryGirl.create(:crop, :system_name => 'Roma tomato', :parent => @tomato)
    assign(:crops, [@tomato, @roma])
    render
  end

  it "shows crop hierarchy" do
    assert_select "ul>li>ul>li", :text => @roma.system_name
  end
end
