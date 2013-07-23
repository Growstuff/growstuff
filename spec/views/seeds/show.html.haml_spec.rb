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
    end

    it "shows tradable attributes" do
      render
      rendered.should contain "Will trade to: locally"
    end

    it "shows location of seed owner" do
      render
      rendered.should contain @owner.location
    end

    context 'with no location' do
      before(:each) do
        @owner = FactoryGirl.create(:member) # no location
        sign_in @owner
        controller.stub(:current_user) { @owner }
        assign(:seed, FactoryGirl.create(:tradable_seed, :owner => @owner))
      end

      it 'says "from unspecified location"' do
        render
        rendered.should contain "(from unspecified location)"
      end

      it "links to profile to set location" do
        render
        assert_select "a[href=#{url_for(edit_member_registration_path)}]", :text => "Set Location"
      end
    end

    it "shows button to send message" do
      render
      rendered.should contain "Request seeds"
    end

  end
end
