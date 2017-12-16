require 'rails_helper'

describe "seeds/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @seed = FactoryBot.create(:seed)
    assign(:seed, @seed)
    assign(:photos, @seed.photos.paginate(page: 1))
  end

  it "renders attributes in <p>" do
    render
    rendered.should have_content @seed.crop.name
  end

  context "tradable" do
    before(:each) do
      @owner = FactoryBot.create(:london_member)
      assign(:seed, FactoryBot.create(:tradable_seed,
        owner: @owner))
      # note current_member is not the owner of this seed
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
    end

    it "shows tradable attributes" do
      render
      rendered.should have_content "Will trade: locally"
    end

    it "shows location of seed owner" do
      render
      rendered.should have_content @owner.location
      assert_select 'a', href: place_path(@owner.location)
    end

    context 'with no location' do
      before(:each) do
        @owner = FactoryBot.create(:member) # no location
        sign_in @owner
        controller.stub(:current_user) { @owner }
        assign(:seed, FactoryBot.create(:tradable_seed, owner: @owner))
      end

      it 'says "from unspecified location"' do
        render
        rendered.should have_content "(from unspecified location)"
      end

      it "links to profile to set location" do
        render
        assert_select "a[href='#{url_for(edit_member_registration_path)}']", text: "Set Location"
      end
    end

    it "shows button to send message" do
      render
      rendered.should have_content "Request seeds"
    end
  end
end
