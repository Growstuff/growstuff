require 'spec_helper'

describe MembersController do

  before :each do
    @member = FactoryGirl.create(:member)
    @posts = [ FactoryGirl.create(:post, :author => @member) ]
    @twitter_auth = FactoryGirl.create(:authentication, :member => @member)
    @flickr_auth = FactoryGirl.create(:flickr_authentication, :member => @member)
  end

  describe "GET index" do
    it "assigns only confirmed members as @members" do
      get :index, {}
      assigns(:members).should eq([@member])
    end
  end

  describe "GET JSON index" do
    it "does NOT provide JSON for members" do
      get :index, :format => 'json'
      response.should_not be_success
    end
  end

  describe "GET show" do

    it "does NOT provide JSON for member profile" do
      get :show, { :id => @member.id , :format => 'json' }
      response.should_not be_success
    end

    it "assigns @posts with the member's posts" do
      get :show, {:id => @member.id}
      assigns(:posts).should eq(@posts)
    end

    it "assigns @twitter_auth" do
      get :show, {:id => @member.id}
      assigns(:twitter_auth).should eq(@twitter_auth)
    end

    it "assigns @flickr_auth" do
      get :show, {:id => @member.id}
      assigns(:flickr_auth).should eq(@flickr_auth)
    end

    it "doesn't show completely nonsense members" do
      lambda { get :show, {:id => 9999} }.should raise_error
    end

    it "doesn't show unconfirmed members" do
      @member2 = FactoryGirl.create(:unconfirmed_member)
      lambda { get :show, {:id => @member2.id} }.should raise_error
    end

  end

  describe "GET member's RSS feed" do
    it "returns an RSS feed" do
      get :show, { :id => @member.to_param, :format => "rss" }
      response.should be_success
      response.should render_template("members/show")
      response.content_type.should eq("application/rss+xml")
    end
  end

  describe "GET nearby members" do
    before(:each) do
      @member_london = FactoryGirl.create(:london_member)
      @member_south_pole = FactoryGirl.create(:south_pole_member)
    end

    context "when the user is logged in and has set their location" do
      before(:each) do
        @member = FactoryGirl.create(:london_member)
        controller.stub(:current_member) { @member }
      end

      it "assigns the current member as nearby" do
        get :nearby
        assigns(:nearby_members).should include @member
      end

      it "assigns nearby members as nearby" do
        get :nearby
        assigns(:nearby_members).should include @member_london
      end

      it "doesn't assign far-off members as nearby" do
        get :nearby
        assigns(:nearby_members).should_not include @member_south_pole
      end

      it "gets members near the specified location if one is set" do
        get :nearby, { :location => @member_south_pole.location }
        assigns(:nearby_members).should include @member_south_pole
      end

      it "does not assign members near current_member if a location is set" do
        get :nearby, { :location => @member_south_pole.location }
        assigns(:nearby_members).should_not include @member_london
      end

      it "finds faraway members if you increase the distance" do
        get :nearby, { :distance => "50000" }
        assigns(:nearby_members).should include @member_south_pole
      end

      # Edinburgh and London are approximately 330mi/530km apart
      it "finds London members within 350 miles of Edinburgh" do 
        get :nearby, { :distance => "350", :units => :mi, :location => "Edinburgh" }
        assigns(:nearby_members).should include @member_london
      end

      it "doesn't find London members within 350 km of Edinburgh" do
        get :nearby, { :distance => "350", :units => :km, :location => "Edinburgh" }
        assigns(:nearby_members).should_not include @member_london
      end

    end

    context "when the user is logged in but hasn't set their location" do
      before(:each) do
        @member = FactoryGirl.create(:member)
        controller.stub(:current_member) { @member }
      end

      it "doesn't assign any members as nearby if no location is set" do
        get :nearby
        assigns(:nearby_members).should == []
      end

      it "assigns nearby members if a location is set" do
        get :nearby, { :location => @member_london.location }
        assigns(:nearby_members).should include @member_london
      end

      it "does not assign far members if a location is set" do
        get :nearby, { :location => @member_london.location }
        assigns(:nearby_members).should_not include @member_south_pole
      end

    end

    context "when the user is not logged in" do
      before(:each) do
        controller.stub(:current_member) { nil }
        get :nearby
      end

      it "doesn't assign any members as nearby if no location is set" do
        get :nearby
        assigns(:nearby_members).should == []
      end

      it "assigns nearby members if a location is set" do
        get :nearby, { :location => @member_london.location }
        assigns(:nearby_members).should include @member_london
      end

      it "does not assign far members if a location is set" do
        get :nearby, { :location => @member_london.location }
        assigns(:nearby_members).should_not include @member_south_pole
      end
    end
  end

end
