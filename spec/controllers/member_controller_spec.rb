require 'spec_helper'

describe MembersController do

  before :each do
    @member = FactoryGirl.create(:member)
    @posts = [ FactoryGirl.create(:post, :author => @member) ]
    @twitter_auth = FactoryGirl.create(:authentication, :member => @member)
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
    it "assigns the requested member as @member" do
      get :show, {:id => @member.id}
      assigns(:member).should eq(@member)
    end

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
      assigns(:posts).should eq(@posts)
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
      @member_near = FactoryGirl.create(:geolocated_member)
      @member_far = FactoryGirl.create(:lonely_geolocated_member)
    end

    context "when the user is logged in and has set their location" do
      before(:each) do
        @member = FactoryGirl.create(:geolocated_member)
        controller.stub(:current_member) { @member }
      end

      it "assigns the current member as nearby" do
        get :nearby
        assigns(:nearby_members).should include @member
      end

      it "assigns nearby members as nearby" do
        get :nearby
        assigns(:nearby_members).should include @member_near
      end

      it "doesn't assign far-off members as nearby" do
        get :nearby
        assigns(:nearby_members).should_not include @member_far
      end

      it "gets members near the specified location if one is set" do
        get :nearby, { :location => @member_far.location }
        assigns(:nearby_members).should include @member_far
      end

      it "does not assign members near current_member if a location is set" do
        get :nearby, { :location => @member_far.location }
        assigns(:nearby_members).should_not include @member_near
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
        get :nearby, { :location => @member_near.location }
        assigns(:nearby_members).should include @member_near
      end

      it "does not assign far members if a location is set" do
        get :nearby, { :location => @member_near.location }
        assigns(:nearby_members).should_not include @member_far
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
        get :nearby, { :location => @member_near.location }
        assigns(:nearby_members).should include @member_near
      end

      it "does not assign far members if a location is set" do
        get :nearby, { :location => @member_near.location }
        assigns(:nearby_members).should_not include @member_far
      end
    end
  end

end
