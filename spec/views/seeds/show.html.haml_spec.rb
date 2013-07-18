require 'spec_helper'

describe "seeds/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed1 = FactoryGirl.create(:seed, :owner => @member)
    assign(:seed, @seed1)
  end

  it "renders attributes in <p>" do
    render
    rendered.should contain @seed1.crop.system_name
  end

  it "shows tradable attributes" do
    assign(:seed, FactoryGirl.create(:tradable_seed)
    render
    rendered.should contain "Tradable: Yes"
    rendered.should contain "Will trade to: locally"
  end
end
