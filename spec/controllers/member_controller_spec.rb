require 'spec_helper'

describe MembersController do

  login_user

  describe "GET index" do
    it "assigns all members as @members" do
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
