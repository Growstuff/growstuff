require 'spec_helper'

describe "seeds/index" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed1 = FactoryGirl.create(:seed, :owner => @member)
    assign(:seeds, [@seed1, @seed1])
  end

  it "renders a list of seeds" do
    render
    assert_select "tr>td", :text => @seed1.crop.system_name, :count => 2
    assert_select "tr>td", :text => @seed1.owner.login_name, :count => 2
    assert_select "tr>td", :text => @seed1.quantity.to_s, :count => 2
  end
end
