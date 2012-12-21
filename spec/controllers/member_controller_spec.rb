require 'spec_helper'

describe MembersController do

  before :each do
    @user1 = User.create!(
      :username => "fred",
      :password => "mynameisfred",
      :email => "fred@example.com",
      :tos_agreement => true
    )
    @user2 = User.create!(
      :username => "bob",
      :password => "mynameisbob",
      :email => "bob@example.com",
      :tos_agreement => true
    )
    @user1.confirm!
  end

  describe "GET index" do
    it "assigns only confirmed members as @members" do
      user = User.find('fred')
      get :index, {}
      assigns(:members).should eq([user])
    end
  end

  describe "GET show" do
    it "assigns the requested member as @member " do
      user = User.find('fred')
      get :show, {:id => user.id}
      assigns(:member).should eq(user)
    end

    it "doesn't show completely nonsense members" do
      lambda { get :show, {:id => 9999} }.should raise_error
    end

    it "doesn't show unconfirmed members" do
      user = User.find('bob')
      lambda { get :show, {:id => user.id} }.should raise_error
    end
  end

  describe "GET member's RSS feed" do
    it "returns an RSS feed" do
      user = User.find('fred')
      get :show, { :id => user.to_param, :format => "rss" }
      response.should be_success
      response.should render_template("members/show")
      response.content_type.should eq("application/rss+xml")
    end
  end
end
