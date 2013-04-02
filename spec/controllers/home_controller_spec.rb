require 'spec_helper'

describe HomeController do

  describe "GET index" do
    it "assigns counts" do
      @planting = FactoryGirl.create(:planting)
      get :index, {}
      assigns(:garden_count).should == 2 # auto-created for member and planting
      assigns(:planting_count).should == 1
      assigns(:crop_count).should == 1
      assigns(:member_count).should == 1
    end

    it "assigns posts and plantings" do
      @post = FactoryGirl.create(:post)
      @planting = FactoryGirl.create(:planting)
      get :index, {}
      assigns(:posts).should eq [@post]
      assigns(:plantings).should eq [@planting]
    end

    context 'logged in' do

      login_member

      it 'assigns member' do
        get :index, {}
        assigns(:member).should be_an_instance_of Member
      end
    end
  end
end
