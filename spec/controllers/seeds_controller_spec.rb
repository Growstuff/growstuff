require 'rails_helper'

describe SeedsController do
  describe "GET index" do
    it "picks up owner from params" do
      owner = FactoryBot.create(:member)
      get :index, owner: owner.slug
      assigns(:owner).should eq(owner)
    end
  end
end
