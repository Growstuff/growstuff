require 'spec_helper'

describe "seeds/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @seed = FactoryGirl.create(:seed)
    assign(:seed, @seed)
  end

  it "renders attributes in <p>" do
    render
    rendered.should contain @seed.crop.system_name
  end

  context "tradable" do
    before(:each) do
      @owner = FactoryGirl.create(:london_member)
      assign(:seed, FactoryGirl.create(:tradable_seed, 
        :owner => @owner))
      # note current_member is not the owner of this seed
      @member = FactoryGirl.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "shows tradable attributes" do
      rendered.should contain "Tradable: Yes"
      rendered.should contain "Will trade to: locally"
    end

    it "shows location of seed owner" do 
      rendered.should contain @owner.location
    end

    it "shows button to send message" do
      rendered.should contain "Request seeds"
    end
  end
end
