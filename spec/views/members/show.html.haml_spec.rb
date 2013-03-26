require 'spec_helper'

describe "members/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
  end

  context "the basics" do
    before(:each) do
      render
    end

    it "shows account creation date" do
      @time = @member.created_at
      rendered.should contain "Member since"
      rendered.should contain @time.strftime("%B %d, %Y")
    end

    it "contains a gravatar icon" do
      assert_select "img", :src => /gravatar\.com\/avatar/
    end

    it "doesn't show the email address" do
      rendered.should_not contain @member.email
    end
  end

  context "gardens and plantings" do
    before(:each) do
      @planting = FactoryGirl.create(:planting, :garden => @garden)
      render
    end

    it "shows the auto-created garden" do
      assert_select "li.active>a", :text => "Garden"
    end

    it "shows the other garden" do
      assert_select "li>a", :text => @garden.name
    end


    it 'shows the garden description' do
      rendered.should contain "This is a totally cool garden"
    end

    it 'renders markdown in the garden description' do
      assert_select "strong", "totally"
    end

    it "shows the plantings in the garden" do
      rendered.should contain @planting.crop.system_name
    end

    it "doesn't show the note about random plantings" do
      rendered.should_not contain "Note: these are a random selection"
    end

    it "does not contain a 'New Garden' link" do
      assert_select "a[href=#garden_new]", false
    end

    it "does not contain a 'New Garden' tab" do
      assert_select "#garden_new", false
    end
  end

  context "signed in member" do
    before(:each) do
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "contains a 'New Garden' link" do
      assert_select "a[href=#garden_new]", :text => "New Garden"
    end

    it "contains an edit profile button" do
      rendered.should contain "Edit Profile"
    end
  end

  context "signed in as different member" do
    before(:each) do
      @member2 = FactoryGirl.create(:member)
      sign_in @member2
      controller.stub(:current_user) { @member2 }
      render
    end

    it "does not contain a 'New Garden' link" do
      assert_select "a[href=#garden_new]", false
    end

    it "does not contain a 'New Garden' tab" do
      assert_select "#garden_new", false
    end  
    
    it "contains no edit settings button" do
      rendered.should_not contain "Edit Settings"
    end
  end

  context "public member" do
    before(:each) do
      @member = FactoryGirl.create(:public_member)
      render
    end

    it "shows the email address" do
      rendered.should contain @member.email
    end
  end

  context "geolocations" do
    before(:each) do
      @member = FactoryGirl.create(:geolocated_member)
      render
    end
    it "shows the location" do
      rendered.should contain @member.location
    end
    it "shows a map" do
      assert_select "img", :src => /maps\.google\.com/
    end
  end

  context "no location stated" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      render
    end
    it "doesn't have a location" do
      @member.location.to_s.should eq ''
    end
    it "doesn't show the location" do
      rendered.should_not contain "Location:"
    end
    it "doesn't show a map" do
      assert_select "img[src*=maps]", false
    end
  end

  context "no about me" do
    before (:each)  do
      @member = FactoryGirl.create(:member,
        :about_me => nil,
        :gardening_since => nil,
        :wish_i_could_grow => nil,
        :gardening_clothes => nil
      )
      render
    end
    it "doesn't show the About: on the profile" do
      rendered.should_not contain "About"
    end
  end

  context "has about me" do
    before (:each) do
      render
    end
    it "shows the About section on the profile" do
      rendered.should contain "About"
    end
  end

end
