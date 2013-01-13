require 'spec_helper'

describe MembersController do

  before :each do
    @member1 = FactoryGirl.create(:member, :login_name => 'fred')
    @member2 = FactoryGirl.create(:unconfirmed_member, :login_name => 'bob')
    @posts = [ FactoryGirl.create(:post, :member => @member1) ]
  end

  describe "GET index" do
    it "assigns only confirmed members as @members" do
      member = Member.find('fred')
      get :index, {}
      assigns(:members).should eq([member])
    end
  end

  describe "GET show" do
    it "assigns the requested member as @member" do
      member = Member.find('fred')
      get :show, {:id => member.id}
      assigns(:member).should eq(member)
    end

    it "assigns @posts with the member's posts" do
      member = Member.find('fred')
      get :show, {:id => member.id}
      assigns(:posts).should eq(@posts)
    end

    it "doesn't show completely nonsense members" do
      lambda { get :show, {:id => 9999} }.should raise_error
    end

    it "doesn't show unconfirmed members" do
      member = Member.find('bob')
      lambda { get :show, {:id => member.id} }.should raise_error
    end

  end

  describe "GET member's RSS feed" do
    it "returns an RSS feed" do
      member = Member.find('fred')
      get :show, { :id => member.to_param, :format => "rss" }
      response.should be_success
      response.should render_template("members/show")
      response.content_type.should eq("application/rss+xml")
    end
  end
end
