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

end
