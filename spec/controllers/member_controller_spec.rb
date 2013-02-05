require 'spec_helper'

describe MembersController do

  before :each do
    @member1 = FactoryGirl.create(:member)
    @posts = [ FactoryGirl.create(:post, :author => @member1) ]
  end

  describe "GET index" do
    it "assigns only confirmed members as @member1s" do
      get :index, {}
      assigns(:members).should eq([@member1])
    end
  end

  describe "GET JSON index" do
    it "does NOT provide JSON for members" do
      get :index, :format => 'json'
      response.should_not be_success
    end
  end

  describe "GET show" do
    it "assigns the requested member as @member1" do
      get :show, {:id => @member1.id}
      assigns(:member).should eq(@member1)
    end

    it "does NOT provide JSON for member profile" do
      get :show, { :id => @member1.id , :format => 'json' }
      response.should_not be_success
    end

    it "assigns @posts with the member's posts" do
      get :show, {:id => @member1.id}
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
      get :show, { :id => @member1.to_param, :format => "rss" }
      response.should be_success
      response.should render_template("members/show")
      response.content_type.should eq("application/rss+xml")
    end
  end
end
