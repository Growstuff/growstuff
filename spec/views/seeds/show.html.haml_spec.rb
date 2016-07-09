## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "seeds/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @seed = FactoryGirl.create(:seed)
    assign(:seed, @seed)
  end

  it "renders attributes in <p>" do
    render
    rendered.should have_content @seed.crop.name
  end

  context "tradable" do
    before(:each) do
      @owner = FactoryGirl.create(:london_member)
      assign(:seed, FactoryGirl.create(:tradable_seed,
        owner: @owner))
      # note current_member is not the owner of this seed
      @member = FactoryGirl.create(:member)
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
        @owner = FactoryGirl.create(:member) # no location
        sign_in @owner
        controller.stub(:current_user) { @owner }
        assign(:seed, FactoryGirl.create(:tradable_seed, owner: @owner))
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
