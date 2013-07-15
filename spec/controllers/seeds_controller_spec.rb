require 'spec_helper'

describe SeedsController do
  describe "GET index" do
    it "picks up owner from params" do
      owner = FactoryGirl.create(:member)
      get :index, {:owner_id => owner.id}
      assigns(:owner).should eq(owner)
    end
  end
end
