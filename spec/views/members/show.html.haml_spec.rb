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

    it "shows the bio" do
      assert_select "h2", "Bio"
      rendered.should contain @member.bio
    end

    it "shows account creation date" do
      @time = @member.created_at
      rendered.should contain "Member since"
      rendered.should contain @time.strftime("%B %d, %Y")
    end

    it "shows account type" do
      rendered.should contain "Free account"
    end

    it "contains a gravatar icon" do
      assert_select "img", :src => /gravatar\.com\/avatar/
    end
  end

  context 'no bio' do
    before(:each) do
      @member = FactoryGirl.create(:no_bio_member)
      render
    end

    it "doesn't show the bio" do
      rendered.should_not contain "Bio"
    end
  end

  context 'twitter' do
    context "no twitter" do
      it "doesn't show twitter link" do
        render
        assert_select "a[href^=http://twitter.com/]", :count => 0
      end
    end
    context 'has twitter' do
      it "shows twitter link" do
        @twitter_auth = FactoryGirl.create(:authentication, :member => @member)
        render
        assert_select "a", :href => "http://twitter.com/#{@twitter_auth.name}"
      end
    end
  end

  context 'flickr' do
    context "no flickr" do
      it "doesn't show flickr link" do
        render
        assert_select "a[href^=http://flickr.com/]", :count => 0
      end
    end
    context 'has flickr' do
      it "shows flickr link" do
        @flickr_auth = FactoryGirl.create(:flickr_authentication, :member => @member)
        render
        assert_select "a", :href => "http://flickr.com/photos/#{@flickr_auth.uid}"
      end
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

    it 'shows the garden description' do
      rendered.should contain "totally cool garden"
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

    it "doesn't show the email address" do
      rendered.should_not contain @member.email
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

    it "contains an edit settings button" do
      rendered.should contain "Edit your profile"
    end

    it "asks you to upgrade your account" do
      rendered.should contain "Upgrade"
    end

    it "contains no send message button" do
      rendered.should_not contain "Send Message"
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

    it "contains a send message button" do
      rendered.should contain "Send Message"
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

    it "doesn't show a send message button" do
      rendered.should_not contain "Send Message"
    end
  end

  context "geolocations" do
    before(:each) do
      @member = FactoryGirl.create(:london_member)
      render
    end
    it "shows the location" do
      rendered.should contain @member.location
    end
    it "shows a map" do
      assert_select "img", :src => /maps\.google\.com/
    end

    it 'includes a link to places page' do
      assert_select 'a', :href => place_path(@member.location)
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

end
