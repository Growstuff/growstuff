require 'spec_helper'

describe PlantingsController do

  login_member

  def valid_attributes
    {
      :garden_id => FactoryGirl.create(:garden, :owner => subject.current_member).id,
      :crop_id => FactoryGirl.create(:crop).id
    }
  end

  describe "GET index" do
    it "picks up owner from params" do
      owner = FactoryGirl.create(:member)
      get :index, {:owner_id => owner.id}
      assigns(:owner).should eq(owner)
    end
  end

  describe "GET new" do

    it "picks up crop from params" do
      crop = FactoryGirl.create(:crop)
      get :new, {:crop_id => crop.id}
      assigns(:crop).should eq(crop)
    end

    it "doesn't die if no crop specified" do
      get :new, {}
      assigns(:crop).should be_a_new(Crop)
    end

    it "picks up garden from params" do
      member = FactoryGirl.create(:member)
      garden = FactoryGirl.create(:garden, :owner => member)
      get :new, {:garden_id => garden.id}
      assigns(:garden).should eq(garden)
    end

    it "doesn't die if no garden specified" do
      get :new, {}
      assigns(:garden).should be_a_new(Garden)
    end

    it "sets the date of the planting to today" do
      get :new, {}
      assigns(:planting).planted_at.should == Date.today
    end

  end

end
